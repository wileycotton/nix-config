{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.nas-layouts.root;

  # Generic function to convert a list to an attrset with index information
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

  # Function to create root disk configuration
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
  options.nas-layouts.root = {
    enable = mkEnableOption "disk layouts for SSDs";

    poolname = mkOption {
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
            acltype = "posixacl";
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
