{
  pkgs,
  unstablePkgs,
  lib,
  config,
  ...
}: {
  services.open-webui = {
    enable = true;
    package = unstablePkgs.open-webui;
    host = "0.0.0.0";
    environment = {
      WEBUI_AUTH = "True";
    };
    environmentFile = config.age.secrets.open-webui.path;
  };

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.age.secrets.tailscale-keys.path;

    services.llm = {
      ephemeral = true;
      toURL = "http://${config.services.open-webui.host}:${toString config.services.open-webui.port}/";
    };
  };


  age.secrets."open-webui" = {
    file = ../../secrets/open-webui.age;
  };
}
