{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.nas-layouts.ssd;
in {
  options.nas-layouts.ssd = {
    enable = mkEnableOption "disk layouts for SSDs";

    name = mkOption {
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
      disk = listToAttrs (map (disk: {
          name = disk;
          value = {
            type = "disk";
            device = "/dev/${disk}";
            content = {
              type = "gpt";
              partitions = {
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = cfg.name;
                  };
                };
              };
            };
          };
        })
        cfg.disks);
    };
  };
}
