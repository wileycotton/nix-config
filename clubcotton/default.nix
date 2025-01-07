{lib, ...}: {
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
  };
}
