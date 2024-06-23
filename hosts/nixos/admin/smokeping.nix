{
  config,
  pkgs,
  ...
}: {
  config = {
    networking.domain = "lan";

    services.smokeping = {
      enable = true;
      webService = true;
      host = "admin";
      targetConfig = ''
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to the SmokePing website of Bob Cotton.

      + ClubCotton
      menu = ClubCotton Hosts

      ++ Router
      menu = UDM Pro
      host = 192.168.5.1

      ++ HomeAssistant
      menu = Home Assistant
      host = 192.168.20.20

      ++ ShellySmoke
      menu = Shelly Smoke Detector
      host = 192.168.20.125

      ++ ShellyCO
      menu = Shelly CO Detector
      host = 192.168.20.83

      + CenturyLink
      menu = Century Link

      ++ UpstreamHop
      menu = Upstream Hop
      host = 75.166.123.123

      + Cloudflare
      menu = Cloudflare DNS

      ++ v4
      menu = Cloudflare DNS v4
      host = 1.1.1.1

      ++ v6
      menu = Cloudflare DNS v6
      host = 2606:4700:4700::1111

      + Google
      menu = Google DNS

      ++ v4
      menu = Google DNS v4
      host = 8.8.8.8

      ++ v6
      menu = Google DNS v6
      host = 2001:4860:4860::8888
    '';
    };
  };
}
