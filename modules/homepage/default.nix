{
  config,
  pkgs,
  ...
}: let
in {
  
    services.homepage-dashboard.enable = true;

    # see also https://github.com/VTimofeenko/monorepo-machine-config/blob/1441574e424ca64f9abb33bc879aa4cd0e29145b/nixosModules/services/home-dashboard/homepage-dashboard.nix
  
}