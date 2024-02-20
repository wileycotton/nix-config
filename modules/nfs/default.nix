{
  config,
  pkgs,
  ...
}: let
in {
  config = {
    services.rpcbind.enable = true; # needed for NFS

    fileSystems."/mnt/docker_volumes" = {
      device = "192.168.5.7:/Multimedia/docker_volumes";
      fsType = "nfs";
      options = ["x-systemd.automount" "noauto"];
    };

    fileSystems."/mnt/music" = {
      device = "192.168.5.7:/Multimedia/Music";
      fsType = "nfs";
      options = ["x-systemd.automount" "noauto"];
    };
  };
}
