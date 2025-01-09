{
  pkgs,
  lib,
  ...
}: {
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };
  virtualisation.oci-containers.backend = "podman";

  # Container
  virtualisation.oci-containers.containers."apache" = {
    image = "httpd:2.4";
    log-driver = "journald";
    extraOptions = [
      "--network-alias=apache"
      "--network=apache_default"
    ];
  };

  systemd.services."podman-apache" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-apache_default.service"
    ];
    requires = [
      "podman-network-apache_default.service"
    ];
    partOf = [
      "podman-compose-apache-root.target"
    ];
    wantedBy = [
      "podman-compose-apache-root.target"
    ];
  };

  # Network
  systemd.services."podman-network-apache_default" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f apache_default";
    };
    script = ''
      podman network inspect apache_default || podman network create apache_default
    '';
    partOf = ["podman-compose-apache-root.target"];
    wantedBy = ["podman-compose-apache-root.target"];
  };

  # Root service
  systemd.targets."podman-compose-apache-root" = {
    unitConfig = {
      Description = "Root target for Apache container.";
    };
    wantedBy = ["multi-user.target"];
  };
}
