{
  config,
  lib,
  pkgs,
  ...
}:
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
            local = {
              type = "zfs_fs";
              options.mountpoint = "none";
            };
            safe = {
              type = "zfs_fs";
              options.mountpoint = "none";
            };
            "local/reserved" = {
              type = "zfs_fs";
              options = {
                mountpoint = "none";
                reservation = "5GiB";
              };
            };
            "local/root" = {
              type = "zfs_fs";
              mountpoint = "/";
              options.mountpoint = "legacy";
              postCreateHook = ''
                zfs snapshot rpool/local/root@blank
              '';
            };
            "local/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                atime = "off";
                canmount = "on";
                mountpoint = "legacy";
                "com.sun:auto-snapshot" = "true";
              };
            };
            "local/log" = {
              type = "zfs_fs";
              mountpoint = "/var/log";
              options = {
                mountpoint = "legacy";
                "com.sun:auto-snapshot" = "true";
              };
            };
            "safe/home" = {
              type = "zfs_fs";
              mountpoint = "/home";
              options = {
                mountpoint = "legacy";
                "com.sun:auto-snapshot" = "true";
              };
            };
          }; # datasets
        }; # zpool
      };
    };
  };
}
