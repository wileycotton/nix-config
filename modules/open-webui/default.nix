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

    package = mkOption {
      type = types.package;
      default = unstablePkgs.open-webui;
      description = "Open WebUI package to use.";
    };

    enableTailscale = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Tailscale support.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Environment variables to set.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the environment file.";
    };

    stateDir = mkOption {
      type = types.path;
      default = "./data";
      description = "State directory for Open WebUI.";
    };
  };

  config = mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      package = cfg.package;
      host = "0.0.0.0";
      stateDir = cfg.stateDir;
      environment = {
        WEBUI_AUTH = "True";
      };
      environmentFile = config.age.secrets.open-webui.path;
    };

    services.tsnsrv = mkIf cfg.enableTailscale {
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
