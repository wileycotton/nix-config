{
  config,
  pkgs,
  unstablePkgs,
  lib,
  ...
}: let
  libedgetpu = pkgs.callPackage ../../pkgs/libedgetpu {};
in {
  services.frigate = {
    enable = true;
    hostname = "frigate";

    settings = {
      detectors = {
        coral = {
          type = "edgetpu";
          device = "pci";
        };
      };

      ffmpeg = {
        hwaccel_args = "preset-vaapi";
        # hwaccel_args = "-vaapi_device /dev/dri/renderD128 -hwaccel_output_format qsv -c:v h264_qsv";
      };

      mqtt = {
        enabled = true;
        host = "192.168.20.20";
        user = "{FRIGATE_MQTT_USER}";
        password = "{FRIGATE_MQTT_PASSWORD}";
      };

      record = {
        enabled = true;
        retain = {
          days = 2;
          mode = "all";
        };
      };

      birdseye = {
        enabled = true;
        mode = "continuous";
      };

      cameras."front-porch" = {
        ffmpeg = {
          inputs = [
            {
              path = "rtsp://192.168.20.140:8554/1080p?mp4";
              roles = ["record"];
            }
            {
              path = "rtsp://192.168.20.140:8554/360p?mp4";
              roles = ["detect"];
            }
          ];
        };
      };

      cameras."back-porch" = {
        ffmpeg.inputs = [
          {
            path = "rtsp://192.168.20.194:8554/1080p?mp4";
            roles = ["record"];
          }
          {
            path = "rtsp://192.168.20.194:8554/360p?mp4";
            roles = ["detect"];
          }
        ];
      };
      cameras."north-side" = {
        ffmpeg = {
          inputs = [
            {
              path = "rtmp://192.168.20.129/bcs/channel0_main.bcs?channel=0&stream=0&user={FRIGATE_CAMERA_USER}&password={FRIGATE_CAMERA_PASSWORD}";
              roles = ["record"];
            }
            {
              path = "rtmp://192.168.20.129/bcs/channel0_ext.bcs?channel=0&stream=2&user={FRIGATE_CAMERA_USER}&password={FRIGATE_CAMERA_PASSWORD}";
              roles = ["detect"];
            }
          ];
          input_args = "-avoid_negative_ts make_zero -flags low_delay -fflags discardcorrupt -strict experimental -rw_timeout 5000000 -use_wallclock_as_timestamps 1 -f live_flv";
          output_args = {
            record = "-f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c copy";
          };
        };
      };

      go2rtc = {
        streams."back-porch" = ["ffmpeg:rtsp://192.168.20.140:8554/1080p?mp4"];
        streams."front-porch" = ["ffmpeg:rtsp://192.168.20.194:8554/1080p?mp4"];
        streams."north-side" = ["ffmpeg:rtmp://192.168.20.129/bcs/channel0_main.bcs?channel=0&stream=0&user={FRIGATE_CAMERA_USER}&password={FRIGATE_CAMERA_PASSWORD}"];
      };
    };
  };
  # systemd.services.frigate.environment.LD_LIBRARY_PATH = "${libedgetpu}/lib";
  systemd.services.frigate.environment.LD_LIBRARY_PATH = lib.makeLibraryPath [
    "${libedgetpu}"
    pkgs.libusb # libusb
  ];
  systemd.services.frigate.serviceConfig = {
    EnvironmentFile = config.age.secrets.mqtt.path;
    AmbientCapabilities = "cap_pefmon";
    CapabilityBoundingSet = "cap_perfmon";
  };
  # append to the render group in nixos
  users.users.frigate.extraGroups = ["render" "video"];
}
