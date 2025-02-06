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
    paperless = {
      enable = mkEnableOption "paperless database support";

      database = mkOption {
        type = types.str;
        default = "paperless";
        description = "Name of the paperless database.";
      };

      user = mkOption {
        type = types.str;
        default = "paperless";
        description = "Name of the paperless database user.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the user's password file.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.paperless.enable) {
    services.postgresql = {
      ensureDatabases = [cfg.paperless.database];
      ensureUsers = [
        {
          name = cfg.paperless.user;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    # Set password from file if passwordFile is provided
    systemd.services.postgresql.postStart = mkIf (cfg.paperless.passwordFile != null) (let
      password_file_path = cfg.paperless.passwordFile;
    in ''
      $PSQL -tA <<'EOF'
        DO $$
        DECLARE password TEXT;
        BEGIN
          password := trim(both from replace(pg_read_file('${password_file_path}'), E'\n', '''));
          EXECUTE format('ALTER ROLE "${cfg.paperless.database}" WITH PASSWORD '''%s''';', password);
        END $$;
      EOF
    '');

    services.clubcotton.postgresql.postStartCommands = let
      sqlFile = pkgs.writeText "paperless-setup.sql" ''
        ALTER SCHEMA public OWNER TO "${cfg.paperless.user}";
      '';
    in [
      ''
        ${lib.getExe' config.services.postgresql.package "psql"} -p ${toString cfg.port} -d "${cfg.paperless.database}" -f "${sqlFile}"
      ''
    ];
  };
}
