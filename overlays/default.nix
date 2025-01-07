args: let
  # Get all .nix files in the current directory except default.nix and test.nix
  overlayFiles =
    builtins.filter
    (f: f != "default.nix" && f != "test.nix" && builtins.match ".*\\.nix$" f != null)
    (builtins.attrNames (builtins.readDir ./.));

  # Import each overlay file with the given args
  overlays = map (f: import (./. + "/${f}") args) overlayFiles;
in
  # Compose all overlays into a single list
  overlays
