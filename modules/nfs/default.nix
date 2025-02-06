{
  config,
  pkgs,
  ...
}: let
in {
  config = {
    services.rpcbind.enable = true; # needed for NFS

    fileSystems."/media" = {
      device = "nas-01.lan:/media";
      fsType = "nfs";
      options = ["x-systemd.automount" "noauto"];
    };
  };
}
