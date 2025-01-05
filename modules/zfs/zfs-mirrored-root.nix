{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.clubcotton.zfs_mirrored_root;
  zfsLib = import ./lib.nix {inherit lib;};

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

    useStandardFilesystems = mkOption {
      type = types.bool;
      description = "Use standard filesystems";
      default = true;
    };

    reservedSize = mkOption {
      type = types.str;
      description = "Size of the reserved space";
      default = "20GiB";
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
    disko.devices = zfsLib.makeZfsMirroredRootConfig {
      inherit (cfg) poolname disks swapSize filesystems volumes useStandardFilesystems reservedSize;
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
