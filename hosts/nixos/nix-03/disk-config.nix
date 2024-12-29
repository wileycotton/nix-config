# Example to create a bios compatible gpt partition
{lib, ...}: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-eui.00000000000000000026b738281a3535";
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
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        }; # partitions
      }; # content
    }; # disk

    zpool = {
      rpool = {
        type = "zpool";
        # mode = "mirror";
        rootFsOptions = {
          acltype = "posixacl";
          dnodesize = "auto";
          canmount = "off";
          xattr = "sa";
          relatime = "on";
          normalization = "formD";
          mountpoint = "none";
          # encryption = "aes-256-gcm";
          # keyformat = "passphrase";
          # keylocation = "prompt";
          # keylocation = "file:///tmp/pass-zpool-rpool";
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };
        # postCreateHook = ''
        #   zfs set keylocation="prompt" rpool
        # '';
        options = {
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
              reservation = "20GiB";
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
          "local/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "local/incus" = {
            type = "zfs_volume";
            size = "300G";
          };
        }; # datasets
      }; # rpool
    }; # zpool
  };
}
