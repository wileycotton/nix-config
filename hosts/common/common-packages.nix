{ config, pkgs, unstablePkgs, inputs, system, ... }:

{

  config = {
    environment.systemPackages = with pkgs; [

        inputs.agenix.packages."${system}".default
        ## unstable
        unstablePkgs.yt-dlp
        unstablePkgs.get_iplayer

        ## stable
      #  asciinema
        bat
        btop
        bitwarden-cli
        ctlptl
        coreutils
        cue
        curl
        diffr # Modern Unix `diff`
        difftastic # Modern Unix `diff`
        dua # Modern Unix `du`
        duf # Modern Unix `df`
        du-dust # Modern Unix `du`
        # direnv # programs.direnv
        #docker
        drill
        drone-cli
        du-dust
        dua
        duf
        entr # Modern Unix `watch`
        esptool
        exa
      #  ffmpeg
      #  fira-code
      #  fira-mono
        fd
        gh
        unstablePkgs.go_1_21
        glow
        go-migrate
        gron
        gnused
        gnumake 
        #htop # programs.htop
        hub
      #  hugo
      #  ipmitool
        inxi
        jetbrains-mono # font
        just
        jq
        kubernetes-helm
        kubectx
        kubectl
        lazydocker
        lazygit
        mage
        mc
        mkdocs
        mosh
        neofetch
        nmap
        # qmk
        ripgrep
        stern
      #  skopeo
      #  smartmontools
      #  terraform
        tree
        unzip
        watch
        wget
        wireguard-tools
        vim
        wezterm
        yq
        zsh

        # requires nixpkgs.config.allowUnfree = true;
        vscode-extensions.ms-vscode-remote.remote-ssh

        # lib.optionals boolean stdenv is darwin
        #mas # mac app store cli
      ];
  };
}