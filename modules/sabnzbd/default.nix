{
  config,
  lib,
  ...
}: with lib; let
  service = "sabnzbd";
  cfg = config.services.clubcotton.${service};
in {
  options.services.clubcotton.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    tailnetHostname = mkOption {
      type = types.nullOr types.str;
      default = "";
      description = "The tailnet hostname to expose the code-server as.";
    };
    tailscaleAuthKeyPath = mkOption {
      type = lib.types.str;
      default = config.age.secrets.tailscale-keys.path;
      description = "The path to the age-encrypted TS auth key";
    };
  };
  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
    };

    # Expose this code-server as a host on the tailnet
    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = cfg.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://127.0.0.1:8080/";
      };
    };
  };
}
