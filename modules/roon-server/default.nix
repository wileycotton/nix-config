{
  config,
  pkgs,
  ...
}: {
  config = {
    services.roon-server.enable = true;
  };
}
