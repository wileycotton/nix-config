{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ./common.nix {inherit lib;};
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

      filesystems = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            type = mkOption {
              type = types.enum ["zfs_fs"];
              description = "Type of ZFS filesystem";
              default = "zfs_fs";
            };
            mountpoint = mkOption {
              type = types.nullOr types.str;
              description = "Mountpoint for the filesystem";
              default = null;
            };
            options = mkOption {
              type = types.attrsOf types.str;
              description = "Filesystem-specific options";
              default = {};
            };
            postCreateHook = mkOption {
              type = types.lines;
              description = "Commands to run after filesystem creation";
              default = "";
            };
          };
        });
        description = "ZFS filesystems to create";
        default = {};
      };

      volumes = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            type = mkOption {
              type = types.enum ["zfs_volume"];
              description = "Type of ZFS volume";
              default = "zfs_volume";
            };
            options = mkOption {
              type = types.attrsOf types.str;
              description = "Volume-specific options";
              default = {};
            };
            postCreateHook = mkOption {
              type = types.lines;
              description = "Commands to run after volume creation";
              default = "";
            };
          };
        });
        description = "ZFS volumes to create";
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

            datasets = cfg.filesystems // cfg.volumes;
          };
        };
      };
    };
  }
