{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.clubcotton.zfs_raidz1;
in {
  options.clubcotton.zfs_raidz1 = {
    enable = mkEnableOption "ZFS RAIDZ1 disk layout";

    poolname = mkOption {
      type = types.str;
      description = "The name of the zpool to create";
    };

    disks = mkOption {
      type = types.listOf types.str;
      description = "List of disk devices to use";
    };
  };

  config = mkIf cfg.enable {
    disko.devices = {
      # Iteration over the list of disks
      disk = listToAttrs (map (disk: {
          name = disk;
          value = {
            type = "disk";
            device = "${disk}";
            content = {
              type = "gpt";
              partitions = {
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = cfg.poolname;
                  };
                };
              };
            };
          };
        })
        # This being the list of disks
        cfg.disks);
      # Setup the zpool
      zpool = {
        "${cfg.poolname}" = {
          type = "zpool";
          mode = "raidz1";
          rootFsOptions = {
            acltype = "posixacl";
          };
          datasets = {
            database = {
              type = "zfs_fs";
              mountpoint = "/db";
              options = {
                mountpoint = "legacy";
                "com.sun:auto-snapshot" = "true";
              };
            };
          };
        };
      };
    };
  };
}
