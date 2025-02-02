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

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the user's password file.";
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
    extensions = with pkgs.postgresql_16.pkgs; [
      pgvector
    ];
    };

    # Set password from file if passwordFile is provided
    systemd.services.postgresql.postStart = mkIf (cfg.open-webui.passwordFile != null) (let
      password_file_path = cfg.open-webui.passwordFile;
    in ''
      $PSQL -tA <<'EOF'
        DO $$
        DECLARE password TEXT;
        BEGIN
          password := trim(both from replace(pg_read_file('${password_file_path}'), E'\n', '''));
          EXECUTE format('ALTER ROLE "${cfg.open-webui.database}" WITH PASSWORD '''%s''';', password);
        END $$;
      EOF
    '');

    services.clubcotton.postgresql.postStartCommands = let
      sqlFile = pkgs.writeText "open-webui-setup.sql" ''
        CREATE EXTENSION IF NOT EXISTS vector;

        ALTER SCHEMA public OWNER TO "${cfg.open-webui.user}";
      '';
    in [
      ''
        ${lib.getExe' config.services.postgresql.package "psql"} -p ${toString cfg.port} -d "${cfg.open-webui.database}" -f "${sqlFile}"
      ''
    ];
  };
}
