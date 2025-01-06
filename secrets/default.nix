{
  config,
  lib,
  ...
}: {
  age.secrets."tailscale-keys.env" = {
    file = ./tailscale-keys.env;
  };
  age.secrets."tailscale-keys" = {
    file = ./tailscale-keys.raw;
  };
  age.secrets."pushover-key" = {
    file = ./pushover-key.age;
    owner = "alertmanager";
    group = "alertmanager";
  };
  age.secrets."pushover-token" = {
    file = ./pushover-token.age;
    owner = "alertmanager";
    group = "alertmanager";
  };
  age.secrets."condo-ha-token" = {
    file = ./condo-ha-token.age;
    owner = "prometheus";
    group = "prometheus";
  };
  age.secrets."homeassistant-token" = {
    file = ./homeassistant-token.age;
    owner = "prometheus";
    group = "prometheus";
  };
  age.secrets."unpoller" = {
    file = ./unpoller.age;
    owner = "unifi-poller";
    group = "unifi-poller";
  };
  age.secrets."grafana-cloud" = {
    file = ./grafana-cloud.age;
  };
  age.secrets."open-webui" = {
    file = ./open-webui.age;
  };
  # Make sure this secretfile is specifying both LIBRESPOT_USERNAME and LIBRESPOT_PASSWORD
  age.secrets.librespot = {
    file = ./librespot.age;
  };
  age.secrets.mopidy = {
    file = ./mopidy.age;
    # owner = "mopidy";
    # group = "mopidy";
  };
  age.secrets."mqtt" = {
    file = ./mqtt.age;
  };
  age.secrets."immich-database" = {
    file = ./immich-database.age;
  };
  age.secrets."wireless-config" = {
    file = ./wireless-config.age;
  };
}
