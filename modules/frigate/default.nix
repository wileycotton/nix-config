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
        host = "192.168.20.20";
        user = "{FRIGATE_MQTT_USER}";
        password = "{FRIGATE_MQTT_PASS}";
      };

      record = {
        enabled = true;
        retain = {
          days = 2;
          mode = "all";
        };
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
    };
  };
  systemd.services.frigate.serviceConfig.EnvironmentFile = config.age.secrets.mqtt.path;
}
