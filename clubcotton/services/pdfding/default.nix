{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.pdfding;
  clubcotton = config.clubcotton; # this fails in tests with the following error aka fuckery
in {
  options.services.clubcotton.pdfding = {
    enable = mkEnableOption "PDFDing Docker pdf hoster";

    

    tailnetHostname = mkOption {
        type = types.str;
        default = "";
    };
  };

  config = mkIf cfg.enable {
    
  };

  # Expose this code-server as a host on the tailnet if tsnsrv module is available
    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = clubcotton.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://${config.services.open-webui.host}:${toString config.services.open-webui.port}/";
      };
    };
}
