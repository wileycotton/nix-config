{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.postgresql;
in {
  options.services.clubcotton.postgresql = {
    open-webui = {
      enable = mkEnableOption "Open WebUI database support";

      database = mkOption {
        type = types.str;
        default = "open-webui";
        description = "Name of the Open WebUI database.";
      };

      user = mkOption {
        type = types.str;
        default = "open-webui";
        description = "Name of the Open WebUI database user.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.open-webui.enable) {
    services.postgresql = {
      ensureDatabases = [cfg.open-webui.database];
      ensureUsers = [
        {
          name = cfg.open-webui.user;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    services.clubcotton.postgresql.postStartCommands = let
      sqlFile = pkgs.writeText "open-webui-setup.sql" ''
        ALTER SCHEMA public OWNER TO "${cfg.open-webui.user}";
      '';
    in [
      ''
        ${lib.getExe' config.services.postgresql.package "psql"} -p ${toString cfg.port} -d "${cfg.open-webui.database}" -f "${sqlFile}"
      ''
    ];
  };
}
