{
  config,
  pkgs,
  unstablePkgs,
  ...
}: let
  libedgetpu = pkgs.callPackage ../../pkgs/libedgetpu { };

in {
 
  services.frigate = {
    enable = true;
    hostname = "frigate";

    settings = {

      # detectors = {
      #   coral = {
      #     type = "edgetpu";
      #     device = "pci";
      #   };
      # };
        


      ffmpeg = {
        hwaccel_args = "preset-vaapi";
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
        ffmpeg.inputs = [
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

      go2rtc = {
        streams."back-porch" = ["ffmpeg:rtsp://192.168.20.140:8554/1080p?mp4"];
        streams."front-porch" = ["ffmpeg:rtsp://192.168.20.194:8554/1080p?mp4"];
      };
    };
  };
  systemd.services.frigate.environment.LD_LIBRARY_PATH = "${libedgetpu}/lib";
  systemd.services.frigate.serviceConfig = {
    EnvironmentFile = config.age.secrets.mqtt.path;
    AmbientCapabilities = "cap_pefmon";
    CapabilityBoundingSet = "cap_perfmon";
  };
  # append to the render group in nixos
  users.users.frigate.extraGroups = [ "render" "video"];
}
