# This is imported as module, from the top-level flake
{ config, pkgs, unstablePkgs, ... }:

{
  environment.systemPackages = import ./../../common/common-packages.nix
    {
      pkgs = pkgs; 
      unstablePkgs = unstablePkgs;
    };
}