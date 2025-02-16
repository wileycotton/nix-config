{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.sesh-config;
  tomlFormat = pkgs.formats.toml {};

  # Session type for better type checking
  sessionType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the session";
      };

      startup_command = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Command to run when starting the session";
      };
    };
  };
in {
  options.programs.sesh-config = {
    enable = lib.mkEnableOption "sesh configuration";

    sessions = lib.mkOption {
      type = lib.types.listOf sessionType;
      default = [];
      description = "List of sesh sessions";
      example = lib.literalExpression ''
        [
          {
            name = "default";
          }
          {
            name = "just";
            startup_command = "cd ~/nix-config && just";
          }
        ]
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      xdg.enable = true;
      xdg.configFile."sesh/sesh.toml" = {
        source = tomlFormat.generate "sesh-config" {
          session = cfg.sessions;
        };
      };
    })
  ];
}
