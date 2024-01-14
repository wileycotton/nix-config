{
  inputs = {
      agenix.url = "github:ryantm/agenix";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
      nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
      nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";

      disko.url = "github:nix-community/disko";
      disko.inputs.nixpkgs.follows = "nixpkgs";

      vscode-server.url = "github:nix-community/nixos-vscode-server";
      
      home-manager.url = "github:nix-community/home-manager/release-23.05";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      
      nix-darwin.url = "github:lnl7/nix-darwin";
      nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self
    , agenix, nixpkgs, nixpkgs-unstable, nixpkgs-darwin
    , home-manager, nix-darwin, vscode-server, disko, ... }:
    let  
      inputs = { inherit agenix nix-darwin home-manager nixpkgs nixpkgs-unstable; };
      # creates correct package sets for specified arch
      genPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      genDarwinPkgs = system: import nixpkgs-darwin {
        inherit system;
        config.allowUnfree = true;
      };
      
    
      # creates a nixos system config
      nixosSystem = system: hostName: username:
        let
          pkgs = genPkgs system;
        in
          nixpkgs.lib.nixosSystem
          {
            inherit system;
            modules = [
              # adds unstable to be available in top-level evals (like in common-packages)
              { _module.args = { 
                  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
                  system = system;
                }; 
              }

              disko.nixosModules.disko
              ./hosts/nixos/${hostName} # ip address, host specific stuff
              vscode-server.nixosModules.default
              home-manager.nixosModules.home-manager
              {
                networking.hostName = hostName;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${username} = { imports = [ ./home/${username}.nix ]; };
              }
              ./hosts/common/nixos-common.nix
              agenix.nixosModules.default
            ];
          };

      # creates a macos system config
      darwinSystem = system: hostName: username:
        let
          pkgs = genDarwinPkgs system;
        in
          nix-darwin.lib.darwinSystem 
          {
            inherit system inputs;

            modules = [
              # adds unstable to be available in top-level evals (like in common-packages)
              { _module.args = { 
                  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
                  system = system;
                }; 
              }

              ./hosts/darwin/${hostName} # ip address, host specific stuff
              home-manager.darwinModules.home-manager 
              {
                networking.hostName = hostName;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${username} = { imports = [ ./home/${username}.nix ]; };
              }
              ./hosts/common/common-packages.nix
              ./hosts/common/darwin-common.nix
              agenix.nixosModules.default
            ];
          };
    in
    {
      darwinConfigurations = {
        bobs-laptop = darwinSystem "aarch64-darwin" "bobs-laptop" "bcotton";
        # magrathea = darwinSystem "aarch64-darwin" "magrathea" "alex";
        # slartibartfast = darwinSystem "aarch64-darwin" "slartibartfast" "alex";
        # awesomo = darwinSystem "aarch64-darwin" "awesomo" "alex";
        # cat-laptop = darwinSystem "aarch64-darwin" "cat-laptop" "alex";
      };

      nixosConfigurations = {
        admin = nixosSystem "x86_64-linux" "admin" "bcotton";
        nix-01 = nixosSystem "x86_64-linux" "nix-01" "bcotton";
        # testnix = nixosSystem "x86_64-linux" "testnix" "bcotton";
      };
    };

}
