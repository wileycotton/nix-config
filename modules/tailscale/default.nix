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
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [config.services.tailscale.port];
    networking.firewall.trustedInterfaces = ["tailscale0"];

    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
      authKeyFile = config.age.secrets.tailscale-keys.path;
    };
  };
}
