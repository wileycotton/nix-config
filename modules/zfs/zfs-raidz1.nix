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
            # https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
            atime = "off"; # check
            acltype = "posixacl"; 
            compression = "lz4"; # check
            xattr = "sa"; # check
            recordsize = "64k"; # check
            dnodesize = "auto";
            canmount = "off";
            relatime = "on";
            normalization = "formD";
            mountpoint = "none";
            "com.sun:auto-snapshot" = "false";
          };
          options = {
            # TODO How to know if this should be 12 or 13?
            # ashift=12 means 4K sectors (used by most modern hard drives), 
            # and ashift=13 means 8K sectors (used by some modern SSDs).
            ashift = "12";
            autotrim = "on";
          };

          datasets = {
            database = {
              type = "zfs_fs";
              mountpoint = "/db";
              options = {
                mountpoint = "legacy";
                recordsize = "8k"; # for postgres
                "com.sun:auto-snapshot" = "true";
              };
            };
          };
        };
      };
    };
  };
}
