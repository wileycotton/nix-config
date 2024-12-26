let
  pkgs = import <nixpkgs> { };
  disko = (builtins.getFlake "github:nix-community/disko").nixosModules.disko;
in
  import (pkgs.path + "/nixos/tests/make-test-python.nix")
