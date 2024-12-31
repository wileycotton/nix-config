{ lib }:

let
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
  makeRootDiskConfig = { disk, swapSize }: {
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
            pool = "zroot";
          };
        };
      };
    };
  };

in {
  inherit rootFsOptions options;

  makeZfsSingleRootConfig = { 
    poolname, 
    disk, 
    swapSize, 
    filesystems ? {},
    volumes ? {} 
  }: {
    disk = {
      ${disk} = makeRootDiskConfig {
        inherit disk swapSize;
      };
    };
    zpool = {
      "${poolname}" = {
        type = "zpool";
        mode = "";  # single disk, no RAID
        rootFsOptions = rootFsOptions;
        options = options;
        datasets = filesystems // volumes;
      };
    };
  };
}
