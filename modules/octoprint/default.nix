{
  config,
  pkgs,
  ...
}: let
in {
  config = {
    services.octoprint.enable = true;
    services.octoprint.plugins = [
      bedlevelvisualizer
      octolapse
    ]
  };
}
