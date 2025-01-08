{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: final: prev: {

  # https://discourse.nixos.org/t/trouble-getting-quicksync-to-work-with-jellyfin/42275/2
  jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
    ffmpeg_7-full = prev.ffmpeg_7-full.override {
      withMfx = false;
      withVpl = true;
    };
  };
}
