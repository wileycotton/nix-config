{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.pdfding;
  clubcotton = config.clubcotton; # this fails in tests with the following error aka fuckery
in {
  options.services.clubcotton.pdfding = {
    enable = mkEnableOption "PDFDing Docker pdf hoster";

    port = mkOption {
      type = types.integer;
      default = "8000";
    };

    dbDir = mkOption {
      type = types.str;
      default = "";
      description = "a full path";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "";
      description = "a full path";
    };

    tailnetHostname = mkOption {
      type = types.str;
      default = "";
    };

    secretKeyPath = mkOption {
      type = types.path;
      default = config.age.secrets.pdfding-secret-key.path;
      description = "Path to file containing the SECRET_KEY";
    };

    databasePasswordPath = mkOption {
      type = types.path;
      default = config.age.secrets.pdfding-database-password.path;
      description = "Path to file containing the PostgreSQL password";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") "${cfg.mediaDir}"; # ideally this is a persistant folder mounted into docker, not a docker only folder.

    virtualisation.oci-containers = {
      containers = {
        sabnzbd = {
          image = "mrmn/pdfding";
          autoStart = true;
          extraOptions = [
            "-p ${cfg.port}:${cfg.port}" # Publish a container's port(s) to the host
            "-v dbDir:${dbDir} -v mediaDir:${mediaDir}"
          ];
          environment = {
            HOST_NAME = "127.0.0.1";
            HOST_PORT = cfg.port;
            SECRET_KEY = builtins.readFile cfg.secretKeyPath;
            CSRF_COOKIE_SECURE = true; # Set this to TRUE to avoid transmitting the CSRF cookie over HTTP accidentally.
            SESSION_COOKIE_SECURE = true; # Set this to TRUE to avoid transmitting the session cookie over HTTP accidentally.

            DATABASE_TYPE = "POSTGRES";
            POSTGRES_HOST = "postgres";
            POSTGRES_PASSWORD = builtins.readFile cfg.databasePasswordPath;
            POSTGRES_PORT = 5432;
          };
        };
      };
    };

    # Expose this code-server as a host on the tailnet if tsnsrv module is available
    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = clubcotton.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://${config.services.open-webui.host}:${toString config.services.open-webui.port}/";
      };
    };
  };
}
