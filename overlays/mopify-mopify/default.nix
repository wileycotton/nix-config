{...}:
# https://nixos.org/manual/nixpkgs/stable/#how-to-override-a-python-package-using-overlays
(final: prev: {
  python3 = prev.python3.override {
    packageOverrides = python-final: python-prev: {
      mopidy-mopify = python-prev.mopidy-mopify.overrideAttrs (oldAttrs: {
        src = prev.fetchPypi {
          pname = "Mopidy-Mopify";
          version = "1.7.3";
          sha256 = "93ad2b3d38b1450c8f2698bb908b0b077a96b3f64cdd6486519e518132e23a5c";
        };
      });
    };
  };
})
