{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.webdav;
in {
  options.services.clubcotton.webdav = {
    enable = mkEnableOption "WebDAV server";

    user = mkOption {
      type = types.str;
      description = "Username for WebDAV authentication";
      example = "webdav-user";
    };

    scope = mkOption {
      type = types.str;
      description = "Directory path to serve via WebDAV";
      example = "/media/webdav/files";
    };

    password = mkOption {
      type = types.str;
      description = "Password for WebDAV authentication";
      example = "your-secure-password";
    };
  };

  config = mkIf cfg.enable {
    # Create the user and group for WebDAV
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = "webdav";
      createHome = false;
      description = "WebDAV service user";
    };

    users.groups.webdav = {};

    services.webdav = {
      enable = true;
      settings = {
        address = "0.0.0.0";
        port = 8080;
        modify = true;
        auth = true;
        directory = ".";
        permissions =  "R";
        users = [
          {
            username = "${cfg.user}";
            password = "${cfg.password}";
            directory = "/var/lib/webdav";
          }
        ];
      };
    };
  };
}
