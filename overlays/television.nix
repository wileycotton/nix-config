{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: self: super: {
  television = unstablePkgs.rustPlatform.buildRustPackage rec {
    pname = "television";
    version = "0.10.2";

    src = pkgs.fetchFromGitHub {
      owner = "alexpasmantier";
      repo = "television";
      rev = "refs/tags/${version}";
      hash = "sha256-VOoRl//Z0AiRv96SqopjUYePPUa9KRbEpLYzJ6k1b8Q=";
    };

    cargoHash = "sha256-ULq3nGz39ACFVtHfCvPsl7Ihc2PPv5lTM2K9xpQm48s=";

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    meta = with lib; {
      description = "Television is a blazingly fast general purpose fuzzy finder";
      longDescription = ''
        Television is a blazingly fast general purpose fuzzy finder TUI written
        in Rust. It is inspired by the neovim telescope plugin and is designed
        to be fast, efficient, simple to use and easily extensible. It is built
        on top of tokio, ratatui and the nucleo matcher used by the helix editor.
      '';
      homepage = "https://github.com/alexpasmantier/television";
      changelog = "https://github.com/alexpasmantier/television/releases/tag/${version}";
      license = licenses.mit;
      mainProgram = "tv";
      maintainers = with maintainers; [
        louis-thevenet
        getchoo
      ];
    };
  };
}
