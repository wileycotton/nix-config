{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.freshrss;
  clubcotton = config.clubcotton;
in {
  options.services.clubcotton.freshrss = {
    enable = mkEnableOption "PDF reader and archiver for documents.";

    port = mkOption {
      type = types.port;
      default = 8080;
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Password for the defaultUser for FreshRSS.";
      example = "/run/secrets/freshrss";
    };

    authType = mkOption {
      type = types.enum ["form" "http_auth" "none"];
      default = "form";
      description = "Authentication type for FreshRSS.";
    };

    tailnetHostname = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    services.nginx.virtualHosts."freshrss" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.port;
        }
      ];
    };

    services.freshrss = {
      enable = cfg.enable;
      passwordFile = cfg.passwordFile;
      baseUrl = "https://127.0.0.1:${toString cfg.port}";
      virtualHost = "freshrss";
      authType = cfg.authType;
    };

    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = clubcotton.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://127.0.0.1:${toString cfg.port}/";
      };
    };
  };
}
