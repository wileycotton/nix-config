{ config, pkgs, ...}:

{
  config = {
    environment.systemPackages = [
	pkgs.snapcast
        pkgs.pulseaudio
    ];


  # PipeWire Stuff
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # https://discourse.nixos.org/t/how-to-enable-upstream-systemd-user-services-declaratively/7649/9
  systemd.packages = [ pkgs.pipewire ];
  systemd.user.services.pipewire.wantedBy = [ "default.target" ];

  # SnapServer Stuff
  services.snapserver = {
    enable = true;
    codec = "flac";
    streams = {
      pipewire  = {
        type = "pipe";
        location = "/run/snapserver/pipewire";
      };
    };
  };

  systemd.user.services.snapcast-sink = {
    wantedBy = [
      "pipewire.service"
    ];
    after = [
      "pipewire.service"
    ];
    bindsTo = [
      "pipewire.service"
    ];
    path = with pkgs; [
      gawk
      pulseaudio
    ];
    script = ''
      pactl load-module module-pipe-sink file=/run/snapserver/pipewire sink_name=Snapcast format=s16le rate=48000
    '';
  };

  systemd.user.services.snapclient-local = {
    wantedBy = [
      "pipewire.service"
    ];
    after = [
      "pipewire.service"
    ];
    serviceConfig = {
      ExecStart = "${pkgs.snapcast}/bin/snapclient -h ::1";
    };
  };

  };
}
