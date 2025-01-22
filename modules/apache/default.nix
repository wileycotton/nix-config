{
  pkgs,
  lib,
  ...
}: {
  # Enable OCI container support
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # Apache container configuration
  virtualisation.oci-containers.containers."apache" = {
    image = "httpd:2.4";
    ports = [
      "8080:8080/tcp"
    ];
    volumes = [
      "/var/lib/apache/htdocs:/usr/local/apache2/htdocs:rw"
    ];
    log-driver = "journald";
    autoStart = true;
  };

  # Ensure the volume directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/apache/htdocs 0755 root root -"
  ];
}
