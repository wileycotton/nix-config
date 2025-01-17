{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.kavita;
in {
  options.services.clubcotton.kavita = {
    enable = mkEnableOption "Kavita server";

    port = mkOption {
      type = types.port;
      default = 8085;
      description = "Port to listen on";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/kavita";
      description = "Directory where Kavita stores its data";
    };

    user = mkOption {
      type = types.str;
      default = "kavita";
      description = "User account under which Kavita runs";
    };

    tokenKeyFile = mkOption {
      type = types.path;
      description = ''
        A file containing the TokenKey (a secret with 512+ bits).
        Generate with: head -c 64 /dev/urandom | base64 --wrap=0
      '';
    };

    bindAddresses = mkOption {
      type = types.listOf types.str;
      default = ["0.0.0.0" "::"];
      description = "IP addresses to bind to (IPv4 and IPv6)";
    };
  };

  config = mkIf cfg.enable {
    services.kavita = {
      enable = true;
      inherit (cfg) user dataDir tokenKeyFile;
      settings = {
        Port = cfg.port;
        IpAddresses = concatStringsSep "," cfg.bindAddresses;
      };
    };
  };
}
