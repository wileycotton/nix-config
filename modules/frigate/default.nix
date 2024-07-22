{
  config,
  pkgs,
  unstablePkgs,
  lib,
  ...
}: let
  libedgetpu = pkgs.callPackage ../../pkgs/libedgetpu {};
in {
  services.go2rtc = {
    enable = true;
    settings.streams = config.services.frigate.settings.go2rtc.streams;
  };

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

      cameras = {
        frontporch = {
          ffmpeg.inputs = [
            {
              path = "rtsp://127.0.0.1:8554/frontporch?video=copy&audio=aac";
              roles = ["record" "detect"];
            }
          ];
        };

        backporch = {
          ffmpeg.inputs = [
            {
              path = "rtsp://127.0.0.1:8554/backporch?video=copy&audio=aac";
              roles = ["record" "detect"];
            }
          ];
        };
        northside = {
          ffmpeg.inputs = [
            {
              path = "rtsp://127.0.0.1:8554/northside?video=copy&audio=aac";
              roles = ["record" "detect"];
            }
          ];
        };
      };

      go2rtc = {
        log = {
          format = "text";
          exec = "trace";
        };

        streams.backporch = [
          "rtsp://192.168.20.194:8554/1080p?mp4"
          "ffmpeg:backporch#video=h264#hardware"
        ];

        streams.frontporch = [
          "rtsp://192.168.20.140:8554/1080p?mp4"
          "ffmpeg:frontporch#video=h264#hardware"
        ];

        streams.northside = [
          "rtmp://192.168.20.129/bcs/channel0_main.bcs?channel=0&stream=0&user=\${FRIGATE_CAMERA_USER}&password=\${FRIGATE_CAMERA_PASSWORD}"
          "ffmpeg:northside#video=h264#hardware"
          ];
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
    AmbientCapabilities = "cap_perfmon";
    CapabilityBoundingSet = "cap_perfmon";
  };
  systemd.services.go2rtc.serviceConfig = {
    EnvironmentFile = config.age.secrets.mqtt.path;
  };
  # append to the render group in nixos
  users.users.frigate.extraGroups = ["render" "video"];
}
