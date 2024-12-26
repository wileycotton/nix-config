{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.code-server;
in {
  imports = [
    inputs.tsnsrv.nixosModules.default
  ];

  options.services.clubcotton.code-server = {
    enable = mkEnableOption "Code Server";

    enableTsnsrv = mkOption {
      type = types.bool;
      default = false;
      description = "Expose this code-server on the tailnet";
    };

    tailnetHostname = mkOption {
      type = lib.types.str;
      default = "";
      description = "The tailnet hostname to expose the code-server as.";
    };

    user = mkOption {
      type = lib.types.str;
      description = "The username to run the code-server as. Typically your user";
    };

    tailscaleAuthKeyPath = mkOption {
      type = lib.types.str;
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
      enable = cfg.enableTsnsrv;
      defaults.authKeyPath = cfg.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = {
        ephemeral = true;
        toURL = "http://${config.services.code-server.host}:${toString config.services.code-server.port}/";
      };
    };
  };
}
