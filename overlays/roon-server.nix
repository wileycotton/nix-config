{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: let
  roonVersion = "2.0-1483";
  roonUrlVersion = builtins.replaceStrings ["." "-"] ["00" "0"] roonVersion;
in
self: super: {
  roon-server = super.roon-server.overrideAttrs {
    version = roonVersion;
    src = pkgs.fetchurl {
      url = "https://download.roonlabs.com/updates/production/RoonServer_linuxx64_${roonUrlVersion}.tar.bz2";
      hash = "sha256-y8MYiWlc3HfF7a3n7yrs84H/9KbEoANd8+7t2ORIm6w=";
    };
  };
}
