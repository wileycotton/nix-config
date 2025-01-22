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
        default = "8000"
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
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

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
            SECRET_KEY = ;
            CSRF_COOKIE_SECURE = true; # Set this to TRUE to avoid transmitting the CSRF cookie over HTTP accidentally.
            SESSION_COOKIE_SECURE = true; # Set this to TRUE to avoid transmitting the session cookie over HTTP accidentally.

            DATABASE_TYPE = "POSTGRES";
            POSTGRES_HOST = "postgres";
            POSTGRES_PASSWORD = "none";
            POSTGRES_PORT = 5432;

            BACKUP_ENABLE = "None"; # The endpoint of the S3 compatible storage. Example: minio.pdfding.com
            BACKUP_ACCESS_KEY = "None"; # The access key of the S3 compatible storage. Example: random_access_key
            BACKUP_SECRET_KEY = "None"; # The secret key of the S3 compatible storage. Example: random_secret_key
            BACKUP_BUCKET_NAMEf = "pdfding"; # The name of the bucket where PdfDing should be backed up to. Example: pdfding
            BACKUP_SCHEDULE = "0 2 * * *"; # The schedule for the periodic backups. Example: 0 2 * * *. This schedule will start the backup every night at 2:00. More information can be found here.
            BACKUP_SECURE = FALSE; # Flag to indicate to use secure (TLS) connection to S3 service or not.
            BACKUP_ENCRYPTION_ENABLE = FALSE; 
            BACKUP_ENCRYPTION_PASSWORD = "None"; # Password used for generating the encryption key. The encryption key generation is done via PBKDF2 with 1000000 iterations.
            BACKUP_ENCRYPTION_SALT = "pdfding";
          };
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
}
