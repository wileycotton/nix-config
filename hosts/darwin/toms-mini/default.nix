# This is imported as module, from the top-level flake
{
  pkgs,
  unstablePkgs,
  lib,
  inputs,
  ...
}: {
  imports = [ ../toms-darwin/default.nix ];

  clubcotton.useP11KitOverlay = false;
}