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
