{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  zfsLib = import ./lib.nix {inherit lib;};
  cfg = config.clubcotton.zfs_raidz1;
in {
  options.clubcotton.zfs_raidz1 = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkEnableOption "ZFS RAIDZ1 disk layout";

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
              size = lib.mkOption {
                type = lib.types.nullOr lib.types.str; # TODO size
                default = null;
                description = "Size of the dataset";
              };
            };
          });
          description = "ZFS volumes to create";
          default = {};
        };
      };
    });
    description = "ZFS RAIDZ1 pool configurations";
    default = {};
  };

  config = {
    disko.devices = mkMerge (mapAttrsToList (poolname: poolcfg:
      mkIf poolcfg.enable (zfsLib.makeZfsRaidz1Config {
        inherit poolname;
        inherit (poolcfg) disks filesystems volumes;
      }))
    cfg);
  };
}
