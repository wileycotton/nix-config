{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ./common.nix { inherit lib; };
in
with lib; let
  cfg = config.clubcotton.zfs_mirrored_root;

  # The equivalent of the ruby's each_with_index
  listToAttrsWithIndex = list:
    listToAttrs (
      genList (
        index: {
          name = builtins.elemAt list index;
          value = {
            index = index;
            item = builtins.elemAt list index;
          };
        }
      ) (builtins.length list)
    );

  # Function to create root disk configuration as
  # part of a mirrored set.
  makeRootDiskConfig = name: _index: {
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
            mountpoint = "/boot${toString _index}";
            # https://discourse.nixos.org/t/nixos-on-mirrored-ssd-boot-swap-native-encrypted-zfs/9215/6
            mountOptions = ["nofail"];
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
  options.clubcotton.zfs_mirrored_root = {
    enable = mkEnableOption "ZFS mirrored root disk layout";

    poolname = mkOption {
      type = types.str;
      description = "The name of the zpool to create";
    };

    disks = mkOption {
      type = types.listOf types.str;
      description = "List of disk devices to use";
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
    disko.devices = {
      # Iteration over the list of disks
      disk = listToAttrs (
        map (diskAttr: {
          name = diskAttr.item;
          value = makeRootDiskConfig diskAttr.item diskAttr.index;
        }) (builtins.attrValues (listToAttrsWithIndex cfg.disks))
      );
      # Setup the zpool
      zpool = {
        "${cfg.poolname}" = {
          type = "zpool";
          mode = "mirror";
          rootFsOptions = common.rootFsOptions;
          options = common.options;
          datasets = cfg.datasets;
        }; # zpool
      };
    };

    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = map (index: {
          devices = ["nodev"];
          path = "/boot${toString index}";
          efiSysMountPoint = "/boot${toString index}";
        }) (range 0 ((length cfg.disks) - 1));
      };
    };
  };
}
