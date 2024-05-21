{
  config,
  pkgs,
  ...
}: let
in {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    # bookmarks = [
    #   {
    #     dev = [
    #       {
    #         github = [
    #           {
    #             abbr = "GH";
    #             href = "https://github.com/";
    #             icon = "github-light.png";
    #           }
    #         ];
    #       }
    #       {
    #         "homepage docs" = [
    #           {
    #             abbr = "HD";
    #             href = "https://gethomepage.dev";
    #             icon = "homepage.png";
    #           }
    #         ];
    #       }
    #     ];
    #   }
    # ];
  };

  # see also https://github.com/VTimofeenko/monorepo-machine-config/blob/1441574e424ca64f9abb33bc879aa4cd0e29145b/nixosModules/services/home-dashboard/homepage-dashboard.nix
}
