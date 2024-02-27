{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: let
  # See https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/
  tmux-window-name =
    pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-window-name";
      version = "head";
      src = pkgs.fetchFromGitHub {
        owner = "ofirgall";
        repo = "tmux-window-name";
        rev = "fe4d65a14f80fb4b681b7e2dcf361ada88733203";
        sha256 = "sha256-3LyS52Bi49IePkA2JbjDxqhooV5V0vT+4Wu+ykWrp0w=";
      };
    };
  tmux-fzf-head =
    pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-fzf";
      version = "head";
      src = pkgs.fetchFromGitHub {
        owner = "sainnhe";
        repo = "tmux-fzf";
        rev = "6b31cbe454649736dcd6dc106bb973349560a949";
        sha256 = "sha256-RXoJ5jR3PLiu+iymsAI42PrdvZ8k83lDJGA7MQMpvPY=";
      };
    };

  nixVsCodeServer = fetchTarball {
    url = "https://github.com/bcotton/nixos-vscode-server/tarball/support-for-new-dir-structure-of-vscode-server";
    sha256 = "sha256:1sp4h0nb7dh7mcm8vdflihv76yz8azf5zifkcbxhq7xz48c8k5pd";
  };
in {
  home.stateVersion = "23.05";

  # list of programs
  # https://mipmip.github.io/home-manager-option-search

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };

  programs.git = {
    enable = true;
    userEmail = "bob.cotton@gmail.com";
    userName = "Bob Cotton";
    extraConfig = {
      alias = {
        br = "branch";
        co = "checkout";
        ci = "commit";
        d = "diff";
        dc = "diff --cached";
        st = "status";
        la = "config --get-regexp alias";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit";
        lga = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit --all";
      };
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
      };
      init.defaultBranch = "main";
      pager.difftool = true;

      core = {
        whitespace = "trailing-space,space-before-tab";
        # pager = "difftastic";
      };
      # interactive.diffFilter = "difft";
      merge.conflictstyle = "diff3";
      diff = {
        # tool = "difftastic";
        colorMoved = "default";
      };
      # difftool."difftastic".cmd = "difft $LOCAL $REMOTE";
    };
    difftastic = {
      enable = false;
      background = "dark";
      display = "side-by-side";
    };
    includes = [
      {path = "${pkgs.delta}/share/themes.gitconfig";}
    ];
    delta = {
      enable = true;
      options = {
        # decorations = {
        #   commit-decoration-style = "bold yellow box ul";
        #   file-decoration-style = "none";
        #   file-style = "bold yellow ul";
        # };
        # features = "mellow-barbet";
        features = "collared-trogon";
        # whitespace-error-style = "22 reverse";
        navigate = true;
        light = false;
        side-by-side = true;
      };
    };
  };

  programs.htop = {
    enable = true;
    settings.show_program_path = true;
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    clock24 = true;
    mouse = true;
    prefix = "C-Space";
    historyLimit = 10000;
    plugins = with pkgs.tmuxPlugins; [
      gruvbox
      tmux-fzf-head
      tmux-colors-solarized
      {
        plugin = tmux-window-name;
      }
    ];
    extraConfig = ''
      new-session -s main
      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind "C-h" select-pane -L
      bind "C-j" select-pane -D
      bind "C-k" select-pane -U
      bind "C-l" select-pane -R
      bind-key "C-f" run-shell -b "${tmux-fzf-head}/share/tmux-plugins/tmux-fzf/scripts/session.sh switch"

      # tmux-fzf stuff
    '';
  };

  imports = [
    "${nixVsCodeServer}/modules/vscode-server/home.nix"
  ];
  services.vscode-server.enable = true;
  services.vscode-server.installPath = "$HOME/.vscode-server";

  # TODO: add ~/bin
  # code --remote ssh-remote+<remoteHost> <remotePath>

  home.file."oh-my-zsh-custom" = {
    enable = true;
    source = ./oh-my-zsh-custom;
    target = ".oh-my-zsh-custom";
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    defaultKeymap = "emacs";
    autocd = true;

    cdpath = [
      "."
      ".."
      "../.."
      "~"
      "~/projects"
    ];

    dirHashes = {
      docs = "$HOME/Documents";
      proj = "$HOME/projects";
      dl = "$HOME/Downloads";
    };

    envExtra = ''
      export DFT_DISPLAY=side-by-side
      export XDG_CONFIG_HOME="$HOME/.config"
      export LESS="-iMSx4 -FXR"
      export PAGER=less
      export EDITOR=vim
      export FULLNAME='Bob Cotton'
      export EMAIL=bob.cotton@gmail.com
      export GOPATH=$HOME/go
      export PATH=$GOPATH/bin:/opt/homebrew/share/google-cloud-sdk/bin:~/projects/deployment_tools/scripts/gcom:~/projects/grafana-app-sdk/target:$PATH
      export OKTA_MFA_OPTION=1

      export GOPRIVATE="github.com/grafana/*"
      export QMK_HOME=~/projects/qmk_firmware
      #export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
      export EXA_COLORS="da=1;35"
      export BAT_THEME="Visual Studio Dark+"
      export TMPDIR=/tmp/

      export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

      [ -e ~/.config/sensitive/.zshenv ] && \. ~/.config/sensitive/.zshenv
    '';

    oh-my-zsh = {
      enable = true;
      custom = "$HOME/.oh-my-zsh-custom";

      theme = "git-taculous";
      # theme = "agnoster-nix";

      extraConfig = ''
        zstyle :omz:plugins:ssh-agent identities id_ed25519
        if [[ `uname` == "Darwin" ]]; then
          zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain
        fi
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '';
      plugins = [
        "brew"
        "bundler"
        "colorize"
        "dotenv"
        "fzf"
        "git"
        "gh"
        "kubectl"
        "kube-ps1"
        "ssh-agent"
        "tmux"
        "z"
      ];
    };

    shellAliases = {
      batj = "bat -l json";
      batly = "bat -l yaml";
      batmd = "bat -l md";
      dir = "exa -l --icons --no-user --group-directories-first  --time-style long-iso --color=always";
      k = "kubectl";
      kctx = "kubectx";
      kns = "kubens";
      ltr = "ll -snew";
      tf = "terraform";
      tree = "exa -Tl --color=always";
      # watch = "watch --color "; # Note the trailing space for alias expansion https://unix.stackexchange.com/questions/25327/watch-command-alias-expansion
      watch = "viddy ";
    };

    initExtra = ''
      tmux-window-name() {
        (${builtins.toString tmux-window-name}/share/tmux-plugins/tmux-window-name/scripts/rename_session_windows.py &)
      }
      if [[ `uname` == "Darwin" ]]; then
        add-zsh-hook chpwd tmux-window-name
      fi
      source <(kubectl completion zsh)

      bindkey -e
      bindkey '^[[A' up-history
      bindkey '^[[B' down-history
      #bindkey -m
      bindkey '\M-\b' backward-delete-word
      bindkey -s "^Z" "^[Qls ^D^U^[G"
      bindkey -s "^X^F" "e "

      setopt autocd autopushd autoresume cdablevars correct correctall extendedglob globdots histignoredups longlistjobs mailwarning  notify pushdminus pushdsilent pushdtohome rcquotes recexact sunkeyboardhack menucomplete always_to_end hist_allow_clobber no_share_history
      unsetopt bgnice


    '';

    #initExtra = (builtins.readFile ../mac-dot-zshrc);
  };

  programs.eza.enable = true;
  programs.eza.enableAliases = true;
  programs.home-manager.enable = true;
  #  programs.neovim.enable = true;
  programs.nix-index.enable = true;
  #  programs.zoxide.enable = true;

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        StrictHostKeyChecking no
        ForwardAgent yes

      Host github.com
        Hostname ssh.github.com
        Port 443
    '';
    matchBlocks = {
    };
  };

  home.packages = with pkgs; [
    #   ## unstable
    #   unstablePkgs.yt-dlp
    #   unstablePkgs.terraform

    #   ## stable
    #   ansible
    #   asciinema
    #   bitwarden-cli
    #   coreutils
    #   # direnv # programs.direnv
    #   #docker
    #   drill
    #   du-dust
    #   dua
    #   duf
    #   esptool
    #   ffmpeg
    #   fd
    #   #fzf # programs.fzf
    #   #git # programs.git
    #   gh
    #   go
    #   gnused
    #   #htop # programs.htop
    #   hub
    #   hugo
    #   ipmitool
    #   jetbrains-mono # font
    #   just
    #   jq
    #   mas # mac app store cli
    #   mc
    #   mosh
    #   neofetch
    #    nmap
    #      (python311.withPackages(ps: with ps; [ libtmux ]))
    #   ripgrep
    #   skopeo
    #   smartmontools
    #   tree
    #   unzip
    #   watch
    #   wget
    #   wireguard-tools
  ];
}
