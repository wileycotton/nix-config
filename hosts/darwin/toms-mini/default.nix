# This is imported as module, from the top-level flake
{
  config,
  pkgs,
  unstablePkgs,
  lib,
  inputs,
  ...
}: {
  imports = [ 
    ../toms-darwin/default.nix
    ../../../modules/toms-kmonad/default.nix
  ];

  services.clubcotton.toms-darwin = {
    enable = true;
    useP11KitOverlay = false;
  };

  services.clubcotton.toms-kmonad = {
    enable = true;
    platform = "darwin";
    macKeyboardName = "Air 75";
  };
}