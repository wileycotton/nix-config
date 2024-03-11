{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    v4l-utils
  ];
  services.octoprint = {
    enable = true;
    # see here for more plugins https://github.com/BBBSnowball/nixcfg/blob/4f807f1eb702e3996d81a6b32ec3ace98fcf72df/hosts/gk3v-pb/3dprint.nix#L6
    plugins = plugins:
      with plugins; [
        bedlevelvisualizer
        # octolapse
      ];
  };

  services.mjpg-streamer = {
    enable = true;
  };
}
