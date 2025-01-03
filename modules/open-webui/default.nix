{
  pkgs,
  unstablePkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.open-webui;
in {
  options.services.clubcotton.open-webui = {
    enable = mkEnableOption "Open WebUI database support";

    database = mkOption {
      type = types.str;
      default = "open-webui";
      description = "Name of the Open WebUI database.";
    };

    user = mkOption {
      type = types.str;
      default = "open-webui";
      description = "Name of the Open WebUI database user.";
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the user's password file.";
    };
  };

  config = mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      package = unstablePkgs.open-webui;
      host = "0.0.0.0";
      # stateDir = "/mnt/docker_volumes/open-webui";
      environment = {
        WEBUI_AUTH = "True";
      };
      environmentFile = config.age.secrets.open-webui.path;
    };

    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = config.age.secrets.tailscale-keys.path;

      services.llm = {
        ephemeral = true;
        toURL = "http://${config.services.open-webui.host}:${toString config.services.open-webui.port}/";
      };
    };

    age.secrets."open-webui" = {
      file = ../../secrets/open-webui.age;
    };
  };
}
