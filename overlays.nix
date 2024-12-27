{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: {
  nixpkgs.overlays = import ./overlays {
    inherit config pkgs lib unstablePkgs;
  };
}
