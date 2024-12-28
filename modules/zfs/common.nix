{lib, ...}: {
  # Common ZFS options shared between different pool configurations
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
}
