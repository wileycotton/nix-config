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

    directory = mkOption {
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

    users.groups.webdav = {};

    services.webdav = {
      enable = true;
      settings = {
        address = "0.0.0.0";
        port = 8080;
        prefix = "/";
        debug = "false";
        log = {
          format = "console";
          colors = true;
          outputs = ["stderr"];
        };
        permissions = "none";
        rulesBehavior = "overwrite";
        users = [
          {
            username = "${cfg.user}";
            password = "${cfg.password}";
            directory = "${cfg.directory}";
            permissions = "CRUD"; # Create Read Update Delete
          }
        ];
      };
    };
  };
}
