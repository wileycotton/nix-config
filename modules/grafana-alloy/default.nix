{
  config,
  pkgs,
  unstablePkgs,
  inputs,
  ...
}: {
  imports = ["${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/alloy.nix"];

  services.alloy = {
    enable = true;
    package = unstablePkgs.grafana-alloy;
  };
}
