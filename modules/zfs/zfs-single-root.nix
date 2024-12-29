{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ./common.nix { inherit lib; };
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
            type = types.lines;
            description = "Commands to run after dataset creation";
            default = "";
          };
        };
      });
      description = "ZFS datasets to create";
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
          datasets = cfg.datasets;
        };
      };
    };
  };
}
