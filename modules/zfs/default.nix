{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./zfs-single-root.nix
    ./zfs-mirrored-root.nix
    ./zfs-raidz1.nix
  ];

  services.prometheus.exporters =
    lib.mkIf (
      config.clubcotton.zfs_single_root.enable
      or false
      || config.clubcotton.zfs_mirrored_root.enable or false
      || config.clubcotton.zfs_raidz1.enable or false
    ) {
      zfs = {
        enable = true;
      };
    };
}
