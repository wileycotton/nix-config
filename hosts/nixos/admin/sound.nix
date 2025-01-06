{
  config,
  pkgs,
  ...
}: {
  config = {
    environment.systemPackages = [
      pkgs.snapcast
      pkgs.pulseaudio
      pkgs.librespot
    ];

    #    sound.enable = true;
    #    hardware.pulseaudio.enable = true;
    #    hardware.pulseaudio.extraConfig = "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1";

    # PipeWire Stuff
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
    systemd.packages = [pkgs.pipewire];
    systemd.user.services.pipewire.wantedBy = ["default.target"];

    # SnapServer Stuff

    systemd.services.snapserver = {
      serviceConfig.EnvironmentFile = config.age.secrets.librespot.path;
    };

    services.avahi.enable = true;
    services.snapserver = {
      enable = true;
      http.docRoot = "${pkgs.snapcast}/share/snapserver/snapweb";
      codec = "flac";
      streams = {
        snapcast = {
          type = "pipe";
          location = "/run/snapserver/pipe";
          query = {
            codec = "pcm";
            #sampleformat = "48000:16:2";
            sampleformat = "44100:16:2";
          };
        };
        librespot = {
          type = "librespot";
          location = "${pkgs.librespot}/bin/librespot";
        };
      };
    };

    #  systemd.user.services.snapcast-sink = {
    #    wantedBy = [
    #      "pipewire.service"
    #      "snapserver.service"
    #    ];
    #    after = [
    #      "pipewire.service"
    #    ];
    #    bindsTo = [
    #      "pipewire.service"
    #    ];
    #    path = with pkgs; [
    #      gawk
    #      pulseaudio
    #    ];
    #    script = ''
    #      pactl load-module module-pipe-sink file=/run/snapserver/pipewire sink_name=snapcast format=s16le rate=44100
    #      #pactl load-module module-pipe-sink file=/run/snapserver/pipewire sink_name=snapcast format=s16le rate=48000
    #    '';
    #  };

    systemd.user.services.snapclient-local = {
      wantedBy = [
        "pipewire.service"
      ];
      after = [
        "pipewire.service"
      ];
      serviceConfig = {
        # https://github.com/badaix/snapcast/issues/920
        ExecStart = "${pkgs.snapcast}/bin/snapclient -h ::1 --hostID foo -s 14 --sampleformat '48000:16:*' ";
      };
    };

    # MPD Stuff
    # This gets added to a systemd "override" file
    systemd.services.mpd.after = pkgs.lib.mkForce ["snapserver.service"];

    services.mpd = {
      group = "users";
      enable = true;
      musicDirectory = "/mnt/music";
      extraConfig = ''
              log_level "verbose"
        #      audio_output {
        #        name "Pulse Audio Output"
        #        type "pulse"
        #        format          "44100:16:2"
        #        server "127.0.0.1"
        #      }

              audio_output {
                  type        "fifo"
                  name        "snapserver"
                  format      "44100:16:2"
                  path        "/run/snapserver/pipe"
                  mixer_type  "software"
              }
              #audio_output {
              #  type "alsa"
              #  name "Alsa"
              #  device "plughw:1,0"
              #  mixer_control "PCM"
              #}
      '';

      # Optional:
      network.listenAddress = "any"; # if you want to allow non-localhost connections
      #startWhenNeeded = true; # systemd feature: only start MPD service upon connection to its socket
    };

    services.ympd.enable = true;

    services.mopidy = {
      enable = true;
      extensionPackages = [
        pkgs.mopidy-spotify
        #  pkgs.mopidy-mopify
        pkgs.mopidy-tunein
        pkgs.mopidy-local
        pkgs.mopidy-musicbox-webclient
        pkgs.mopidy-iris
      ];
      extraConfigFiles = [config.age.secrets.mopidy.path];
      configuration = ''
        [spotify]
        bitrate = 320
        volume_normalization = false
        private_session = false
        timeout = 20
        allow_cache = true
        allow_network = true
        allow_playlists = true
        search_album_count = 20
        search_artist_count = 10
        search_track_count = 50
        toplist_countries =

        [tunein]
        enabled = true

        [local]
        media_dir = /mnt/music

        [mopify]
        enabled = true
        debug = false

        [iris]
        country = us
        locale = en_US


        [http]
        enabled = true
        hostname = ::
        default_app = mopidy
        #default_app = musicbox_webclient
        #port = <port> # Changeme
        #static_dir =
        #zeroconf = brook

        [audio]
        output = audioresample ! audioconvert ! audio/x-raw,rate=44100,channels=2,format=S16LE ! wavenc ! filesink location=/run/snapserver/pipe
      '';
    };
  };
}
