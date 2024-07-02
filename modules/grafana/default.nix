{
  config,
  pkgs,
  ...
}: {
  services.grafana = {
    enable = true;
    settings.server.http_port = 3000;
    settings.server.http_addr = "0.0.0.0";
    declarativePlugins = with pkgs.grafanaPlugins; [
      grafana-piechart-panel
      grafana-clock-panel
      (grafanaPlugin {
        pname = "yesoreyeram-infinity-datasource";
        version = "0.8.8";
        zipHash = "sha256-SiG3fimQjJ+qLq59So6zaGanpf8gg8sjsFSMfABf62o=";
      })
      (grafanaPlugin {
        pname = "natel-discrete-panel";
        version = "0.0.9";
        zipHash = "sha256-GiZCE9/ZXuRCukVIfVWvrv0GUEioiseAv7sOLwk128Q=";
      })
    ];
  };
}
