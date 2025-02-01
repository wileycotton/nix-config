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
    enable = mkEnableOption "FreshRSS RSS aggregator and reader";

    extensions = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional extensions to be used.";
    };

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
    services.freshrss = {
      enable = cfg.enable;
      passwordFile = cfg.passwordFile;
      baseUrl = "http://127.0.0.1:${toString cfg.port}";
      virtualHost = "freshrss";
      authType = cfg.authType;
      extensions = with pkgs.freshrss-extensions; [];
    };

    services.nginx.virtualHosts."freshrss" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.port;
        }
      ];
      
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        
        # PHP Session handling
        fastcgi_param PHP_VALUE "session.cookie_httponly=1; session.cookie_secure=1; session.use_only_cookies=1";
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_PROXY "";
        
        # Cookie handling
        proxy_cookie_path / "/; secure; HttpOnly; SameSite=Strict";
        proxy_cookie_domain $host $host;
        
        # Additional security headers
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-XSS-Protection "1; mode=block";
      '';
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
