{lib}: let
  # Function to generate standard filesystem configurations
  makeStandardRootFilesystems = {
    reservedSize ? "20GiB",
    poolname,
  }: {
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
        reservation = reservedSize;
      };
    };
    "local/root" = {
      type = "zfs_fs";
      mountpoint = "/";
      options.mountpoint = "legacy";
      postCreateHook = ''
        if ! zfs list -t snapshot ${poolname}/local/root@blank >/dev/null 2>&1; then
          zfs snapshot ${poolname}/local/root@blank
        fi
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
    "local/lib" = {
      type = "zfs_fs";
      mountpoint = "/var/lib";
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
  };

  # Common ZFS options shared between different pool configurations
  rootFsOptions = {
    atime = "off";
    acltype = "posixacl";
    compression = "lz4";
    xattr = "sa";
    recordsize = "64k";
    dnodesize = "auto";
    canmount = "off";
    relatime = "on";
    normalization = "formD";
    mountpoint = "none";
    "com.sun:auto-snapshot" = "false";
  };

  options = {
    ashift = "12";
    autotrim = "on";
  };

  # Function to create root disk configuration for single disk setup
  makeRootDiskPartitionConfig = {
    disk,
    swapSize,
    poolname,
  }: {
    type = "disk";
    device = disk;
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
          size = swapSize;
          content = {
            type = "swap";
            randomEncryption = true;
            priority = 100;
          };
        };
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = poolname;
          };
        };
      };
    };
  };

  # Function to create disk configuration for RAIDZ1 pool members
  makeRaidz1DiskConfig = {
    disk,
    dataPoolName,
  }: {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = dataPoolName;
          };
        };
      };
    };
  };
in {
  inherit rootFsOptions options;

  makeZfsRaidz1Config = {
    poolname,
    dataPoolName ? poolname,
    disks,
    filesystems ? {},
    volumes ? {},
    reservedSize ? "20GiB",
  }: {
    disk = lib.listToAttrs (map (disk: {
        name = disk;
        value = makeRaidz1DiskConfig {
          inherit disk dataPoolName;
        };
      })
      disks);
    zpool = {
      "${dataPoolName}" = {
        type = "zpool";
        mode = "raidz1";
        rootFsOptions = rootFsOptions;
        options = options;
        datasets = filesystems // volumes;
      };
    };
  };

  makeZfsSingleRootConfig = {
    poolname,
    disk,
    swapSize,
    filesystems ? {},
    volumes ? {},
    useStandardFilesystems ? true,
    reservedSize ? "20GiB",
  }: {
    disk = {
      ${disk} = makeRootDiskPartitionConfig {
        inherit disk swapSize poolname;
      };
    };
    zpool = {
      "${poolname}" = {
        type = "zpool";
        mode = ""; # single disk, no RAID
        rootFsOptions = rootFsOptions;
        options = options;
        datasets =
          (
            if useStandardFilesystems
            then makeStandardRootFilesystems {inherit reservedSize poolname;}
            else {}
          )
          // filesystems
          // volumes;
      };
    };
  };

  # Function to create disk configuration for mirrored root setup
  makeZfsMirroredRootConfig = {
    poolname,
    disks,
    swapSize,
    filesystems ? {},
    volumes ? {},
    useStandardFilesystems ? true,
    reservedSize ? "20GiB",
  }: {
    disk = lib.listToAttrs (lib.imap0 (index: disk: {
        name = disk;
        value = {
          type = "disk";
          device = disk;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "256M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot${toString index}";
                  mountOptions = ["nofail"];
                };
              };
              encryptedSwap = {
                size = swapSize;
                content = {
                  type = "swap";
                  randomEncryption = true;
                  priority = 100;
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = poolname;
                };
              };
            };
          };
        };
      })
      disks);
    zpool = {
      "${poolname}" = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = rootFsOptions;
        options = options;
        datasets =
          (
            if useStandardFilesystems
            then makeStandardRootFilesystems {inherit reservedSize poolname;}
            else {}
          )
          // filesystems
          // volumes;
      };
    };
  };
}
