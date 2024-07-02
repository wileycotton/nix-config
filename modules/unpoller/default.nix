{
  config,
  pkgs,
  ...
}: {
  services.unpoller = {
    enable = true;

    prometheus.disable = false;
    prometheus.report_errors = true;

    influxdb.disable = true;

    unifi = {
      controllers = [
        {
          user = "unifipoller";
          pass = config.age.secrets.unpoller.path;
          url = "https://192.168.5.1";
          sites = "all";
          save_sites = true;
          save_dpi = true;
          verify_ssl = false;
        }
      ];
    };
  };
}
