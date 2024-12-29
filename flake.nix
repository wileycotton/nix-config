{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    nixinate.url = "github:matthewcroughan/nixinate";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-shell.url = "github:Mic92/nixos-shell";

    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    agenix,
    nixinate,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-darwin,
    nixos-generators,
    nixos-shell,
    home-manager,
    nix-darwin,
    tsnsrv,
    vscode-server,
    disko,
    ...
  }: let
    inputs = {inherit agenix nixinate nixos-shell nix-darwin home-manager tsnsrv nixpkgs nixpkgs-unstable;};

    # creates correct package sets for specified arch
    genPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    genDarwinPkgs = system:
      import nixpkgs-darwin {
        inherit system;
        config.allowUnfree = true;
      };

    # creates a nixos system config
    nixosVM = system: hostName: usernames: let
      pkgs = genPkgs system;
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
      nixos-generators.nixosGenerate
      {
        format = "lxc";
        specialArgs = {inherit self system inputs;};
        modules =
          [
            # adds unstable to be available in top-level evals (like in common-packages)
            {
              _module.args = {
                unstablePkgs = unstablePkgs;
                system = system;
                inputs = inputs;
              };
            }
            ./overlays.nix

            ./hosts/nixos/${hostName} # ip address, host specific stuff
            vscode-server.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              networking.hostName = hostName;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = builtins.listToAttrs (map (username: {
                  name = username;
                  value = {
                    imports = [./home/${username}.nix];
                  };
                })
                usernames);
              home-manager.extraSpecialArgs = {inherit unstablePkgs;};
            }
            ./hosts/common/common-packages.nix
            ./hosts/common/nixos-common.nix
            agenix.nixosModules.default
          ]
          ++ (map (username: ./users/${username}.nix) usernames);
      };

    # creates a nixos system config
    nixosSystem = system: hostName: usernames: let
      pkgs = genPkgs system;
      nixinateConfig = {
        host = hostName;
        sshUser = "root";
        buildOn = "remote";
        hermetic = false;
      };
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
      nixpkgs.lib.nixosSystem
      {
        inherit system;
        specialArgs = {inherit self system inputs;};
        modules =
          [
            # adds unstable to be available in top-level evals (like in common-packages)
            {
              _module.args = {
                unstablePkgs = unstablePkgs;
                system = system;
                inputs = inputs;
                nixinate = nixinateConfig;
              };
            }

            # To repl the flake
            # > nix repl
            # > :lf .
            # > e.g. admin.[tab]
            # add the following inline module definition
            #   here, all parameters of modules are passed to overlays
            # (args: { nixpkgs.overlays = import ./overlays args; })
            ## or
            ./overlays.nix
            nixos-generators.nixosModules.all-formats

            disko.nixosModules.disko
            ./modules/zfs/zfs-single-root.nix
            ./modules/zfs/zfs-mirrored-root.nix
            ./modules/zfs/zfs-raidz1.nix

            ./hosts/nixos/${hostName} # ip address, host specific stuff
            vscode-server.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              networking.hostName = hostName;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = builtins.listToAttrs (map (username: {
                  name = username;
                  value = {
                    imports = [./home/${username}.nix];
                  };
                })
                usernames);
              home-manager.extraSpecialArgs = {inherit unstablePkgs;};
            }
            ./hosts/common/common-packages.nix
            ./hosts/common/nixos-common.nix
            agenix.nixosModules.default
          ]
          ++ (map (username: ./users/${username}.nix) usernames);
      };

    # creates a nixos system config
    nixosMinimalSystem = system: hostName: usernames: let
      pkgs = genPkgs system;
      nixinateConfig = {
        host = hostName;
        sshUser = "root";
        buildOn = "remote";
        hermetic = false;
      };
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
      nixpkgs.lib.nixosSystem
      {
        inherit system;
        specialArgs = {inherit self system inputs;};
        modules =
          [
            # adds unstable to be available in top-level evals (like in common-packages)
            {
              _module.args = {
                unstablePkgs = unstablePkgs;
                system = system;
                inputs = inputs;
                nixinate = nixinateConfig;
              };
            }

            disko.nixosModules.disko
            ./modules/zfs/zfs-single-root.nix
            ./modules/zfs/zfs-mirrored-root.nix
            ./modules/zfs/zfs-raidz1.nix

            ./hosts/nixos/${hostName} # ip address, host specific stuff
          ]
          ++ (map (username: ./users/${username}.nix) usernames);
      };

    # creates a macos system config
    darwinSystem = system: hostName: username: let
      pkgs = genDarwinPkgs system;
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
      nix-darwin.lib.darwinSystem
      {
        inherit system inputs;

        modules = [
          # adds unstable to be available in top-level evals (like in common-packages)
          {
            _module.args = {
              unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
              system = system;
            };
          }

          ./overlays.nix
          ./hosts/darwin/${hostName} # ip address, host specific stuff
          home-manager.darwinModules.home-manager
          {
            networking.hostName = hostName;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = {
              imports = [./home/${username}.nix];
            };
            home-manager.extraSpecialArgs = {inherit unstablePkgs;};
          }
          ./hosts/common/common-packages.nix
          ./hosts/common/darwin-common.nix
          agenix.nixosModules.default
        ];
      };
  in {
    checks.x86_64-linux = {
      postgresql = nixpkgs.legacyPackages.x86_64-linux.nixosTest (import ./modules/postgresql/test.nix { inherit inputs; });
    };

    apps.nixinate = (nixinate.nixinate.x86_64-linux self).nixinate;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
    formatter.x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;

    darwinConfigurations = {
      bobs-laptop = darwinSystem "aarch64-darwin" "bobs-laptop" "bcotton";
      toms-MBP = darwinSystem "x86_64-darwin" "toms-MBP" "tomcotton";
      bobs-imac = darwinSystem "x86_64-darwin" "bobs-imac" "bcotton";
    };

    nixosConfigurations = {
      admin = nixosSystem "x86_64-linux" "admin" ["bcotton"];
      nas-01 = nixosSystem "x86_64-linux" "nas-01" ["bcotton" "tomcotton"];
      nix-01 = nixosSystem "x86_64-linux" "nix-01" ["bcotton" "tomcotton"];
      nix-02 = nixosSystem "x86_64-linux" "nix-02" ["bcotton" "tomcotton"];
      nix-03 = nixosSystem "x86_64-linux" "nix-03" ["bcotton" "tomcotton"];
      dns-01 = nixosSystem "x86_64-linux" "dns-01" ["bcotton"];
      octoprint = nixosSystem "x86_64-linux" "octoprint" ["bcotton" "tomcotton"];
      frigate-host = nixosSystem "x86_64-linux" "frigate-host" ["bcotton"];
      nixos = nixosSystem "x86_64-linux" "nixos" ["bcotton" "tomcotton"];
      k3s-01 = nixosSystem "x86_64-linux" "k3s-01" ["bcotton"];
      k3s-02 = nixosSystem "x86_64-linux" "k3s-02" ["bcotton"];
      k3s-03 = nixosSystem "x86_64-linux" "k3s-03" ["bcotton"];
      nixbox = nixosSystem "x86_64-linux" "nixbox" ["bcotton" "tomcotton"];
      incus = nixosMinimalSystem "x86_64-linux" "incus" ["bcotton"];
      nas-test = nixosMinimalSystem "x86_64-linux" "nas-test" ["bcotton"];
    };
  };
}
