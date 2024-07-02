{
  config,
  pkgs,
  unstablePkgs,
  ...
}: {
  services.frigate = {
    enable = true;
    hostname = "frigate";

    settings = {
      # ffmpeg = {
      #   hwaccel_args = "preset-vaapi";
      # };

      mqtt = {
        enabled = true;
        host = "homeassistant";
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
        streams."back-porch" = ["rtsp://192.168.20.140:8554/1080p?mp4"];
        streams."front-porch" = ["rtsp://192.168.20.194:8554/1080p?mp4"];
      };
    };
  };
  systemd.services.frigate.serviceConfig.EnvironmentFile = config.age.secrets.mqtt.path;
}
