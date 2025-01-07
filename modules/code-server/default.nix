{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.code-server;
in {
  options.services.clubcotton.code-server = {
    enable = mkEnableOption "Code Server";

    tailnetHostname = mkOption {
      type = types.nullOr types.str;
      default = "";
      description = "The tailnet hostname to expose the code-server as.";
    };

    user = mkOption {
      type = lib.types.str;
      description = "The username to run the code-server as. Typically your user";
    };

    tailscaleAuthKeyPath = mkOption {
      type = lib.types.str;
      default = config.age.secrets.tailscale-keys.path;
      description = "The path to the age-encrypted TS auth key";
    };
  };

  config = mkIf cfg.enable {
    services.code-server = {
      enable = cfg.enable;
      auth = "none"; # Protected by Tailscale
      disableTelemetry = true;
      disableUpdateCheck = true;
      disableWorkspaceTrust = true;
      disableGettingStartedOverride = true;
      host = "0.0.0.0";

      user = cfg.user;
      extraPackages = with pkgs; [
        nil
      ];
    };

    # Expose this code-server as a host on the tailnet
    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = cfg.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://${config.services.code-server.host}:${toString config.services.code-server.port}/";
      };
    };
  };
}
