{lib, config, ...}: {
  imports = [
    ./services
  ];

  options.clubcotton = {
    user = lib.mkOption {
      default = "share";
      type = lib.types.str;
      description = ''
        User to run the homelab services as
      '';
      #apply = old: builtins.toString config.users.users."${old}".uid;
    };
    group = lib.mkOption {
      default = "share";
      type = lib.types.str;
      description = ''
        Group to run the homelab services as
      '';
      #apply = old: builtins.toString config.users.groups."${old}".gid;
    };
    tailscaleAuthKeyPath = lib.mkOption {
      type = lib.types.str;
      default = config.age.secrets.tailscale-keys.path;
      description = "The path to the age-encrypted TS auth key";
    };

  };
}
