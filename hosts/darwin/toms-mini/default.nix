# This is imported as module, from the top-level flake
{
  pkgs,
  unstablePkgs,
  lib,
  inputs,
  ...
}: let
  sharedConfig = import ../shared;
in
{
  imports = [ sharedConfig ];

  # Override defaults for this machine
  mySystem = {
    enableGUI = true;
    defaultApplications = [ "vim" "git" "tmux" "firefox" ];
  };

  # Machine-specific configuration here
  networking.hostName = "machine1";
}