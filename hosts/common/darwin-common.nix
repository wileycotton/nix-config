{
  config,
  pkgs,
  unstablePkgs,
  inputs,
  ...
}: {
  config = {
        # These are packages are just for darwin systems
    environment.systemPackages = [
      pkgs.kind
      unstablePkgs.esphome
    ];

    system.stateVersion = 5;

    nix = {
      #package = lib.mkDefault pkgs.unstable.nix;
      settings = {
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
      };
    };
    services.nix-daemon.enable = true;

    # pins to stable as unstable updates very often
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.registry = {
      n.to = {
        type = "path";
        path = inputs.nixpkgs;
      };
      u.to = {
        type = "path";
        path = inputs.nixpkgs-unstable;
      };
    };
  };
}
