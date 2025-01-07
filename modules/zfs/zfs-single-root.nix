{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  zfsLib = import ./lib.nix {inherit lib;};
  cfg = config.clubcotton.zfs_single_root;
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

    useStandardRootFilesystems = mkOption {
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
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    disko.devices = zfsLib.makeZfsSingleRootConfig {
      inherit (cfg) poolname disk swapSize filesystems volumes useStandardRootFilesystems reservedSize;
    };
  };
}
