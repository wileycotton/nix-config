{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.nas-layouts.ssd;
in {
  options.nas-layouts.ssd = {
    enable = mkEnableOption "disk layouts for SSDs";

    name = mkOption {
      type = types.str;
      description = "Name of the SSD disk layout";
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
                    pool = cfg.name;
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
        "${cfg.name}" = {
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
