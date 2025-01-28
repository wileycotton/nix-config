{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.paperless;
  clubcotton = config.clubcotton; # this fails in tests with the following error aka fuckery
in {
  options.services.clubcotton.paperless = {
    enable = mkEnableOption "PDF reader and archiver for documents.";
    user = mkOption {
        type = types.str;
        default = "paperless";
    };
    port = mkOption {
        type = lib.types.port;
        default = 28981;
    };
    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/paperless";
    };
    consumptionDir = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    passwordFile = lib.mkOption {
      type = lib.types.path;
    };

    tailnetHostname = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;
      passwordFile = cfg.passwordFile;
      user = cfg.user;
      mediaDir = cfg.mediaDir;
      consumptionDir = cfg.consumptionDir;
      consumptionDirIsPublic = true;
      settings = {
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
      };
    };

    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = clubcotton.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://127.0.0.1:${toString cfg.port}/";
      };
    };
  };
}
