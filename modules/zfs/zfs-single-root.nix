{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ./common.nix {inherit lib;};
in
  with lib; let
    cfg = config.clubcotton.zfs_single_root;

    # Function to create root disk configuration
    makeRootDiskConfig = name: {
      type = "disk";
      device = name;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "256M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          encryptedSwap = {
            size = cfg.swapSize;
            content = {
              type = "swap";
              randomEncryption = true;
              priority = 100; # prefer to encrypt as long as we have space for it
            };
          };
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
  in {
    options.clubcotton.zfs_single_root = {
      enable = mkEnableOption "ZFS single disk root layout";

      poolname = mkOption {
        type = types.str;
        description = "The name of the zpool to create";
      };

      disk = mkOption {
        type = types.str;
        description = "Disk device to use for root filesystem";
      };

      swapSize = mkOption {
        type = types.str;
        description = "Size of the swap partition";
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

    config = mkIf cfg.enable {
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      disko.devices = {
        disk = {
          ${cfg.disk} = makeRootDiskConfig cfg.disk;
        };
        zpool = {
          "${cfg.poolname}" = {
            type = "zpool";
            mode = ""; # single disk, no RAID
            rootFsOptions = common.rootFsOptions;
            options = common.options;
            datasets = cfg.filesystems // cfg.volumes;
          };
        };
      };
    };
  }
