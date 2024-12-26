let
  pkgs = import <nixpkgs> { };
  disko = builtins.fetchGit {
    url = "https://github.com/nix-community/disko";
    ref = "master";
  };
in
args@{ ... }:
import (pkgs.path + "/nixos/tests/make-test-python.nix") (args // {
  imports = [ (disko + "/module.nix") ] ++ (args.imports or []);
})
