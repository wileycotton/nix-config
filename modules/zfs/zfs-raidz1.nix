{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ./common.nix { inherit lib; };
in
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

    datasets = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          type = mkOption {
            type = types.str;
            description = "Type of ZFS dataset";
            default = "zfs_fs";
          };
          mountpoint = mkOption {
            type = types.nullOr types.str;
            description = "Mountpoint for the dataset";
            default = null;
          };
          options = mkOption {
            type = types.attrsOf types.str;
            description = "Dataset-specific options";
            default = {};
          };
          postCreateHook = mkOption {
            type = types.nullOr types.str;
            description = "Commands to run after dataset creation";
            default = null;
          };
        };
      });
      description = "ZFS datasets to create";
      default = {};
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
          rootFsOptions = common.rootFsOptions;
          options = common.options;

          datasets = cfg.datasets;
        };
      };
    };
  };
}
