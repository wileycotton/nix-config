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
    # stateDir = "/mnt/docker_volumes/open-webui";
    environment = {
      WEBUI_AUTH = "True";
      ENABLE_OLLAMA_API = "True";
      OLLAMA_BASE_URL = "http://toms-mini:11434";
      OLLAMA_API_BASE_URL = "http://toms-mini:11434";
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
