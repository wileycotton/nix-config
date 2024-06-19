{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    v4l-utils
    ustreamer
  ];
  services.octoprint = {
    enable = true;
    # see here for more plugins https://github.com/BBBSnowball/nixcfg/blob/4f807f1eb702e3996d81a6b32ec3ace98fcf72df/hosts/gk3v-pb/3dprint.nix#L6
    plugins = plugins:
      with plugins; [
        bedlevelvisualizer
        themeify
        # octolapse
      ];
  };

  services.mjpg-streamer = {
    enable = true;
    # using yuv mode, see https://github.com/jacksonliam/mjpg-streamer/issues/236
    # -> limited to VGA resolution
    #inputPlugin = "input_uvc.so -d /dev/video0 -r 1920x1080 -f 15 -y";
    # This seems to work well enough.
    inputPlugin = "input_uvc.so -d /dev/video0 -r 1280x720 --minimum_size 4096";
  };

  networking.firewall.allowedTCPPorts = [5000 5050];

  # don't abort a running print, please
  # (NixOS will tell us when a restart is necessary and we can do it at a time of our choosing.)
  systemd.services.octoprint.restartIfChanged = false;
}
