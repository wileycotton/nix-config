{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.services.tailscale;
in {
  options.services.clubcotton.services.tailscale = {
    enable = mkEnableOption "tailscale service";

    authKeyFile = mkOption {
      type = types.path;
      description = "Path to the file containing the Tailscale authentication key";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.tailscale-key = {
      file = cfg.authKeyFile;
      mode = "0440";
    };

    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
      authKeyFile = config.age.secrets.tailscale-key.path;
    };
  };
}
