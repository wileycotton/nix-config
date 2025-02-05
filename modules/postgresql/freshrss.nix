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
    freshrss = {
      enable = mkEnableOption "freshrss database support";

      database = mkOption {
        type = types.str;
        default = "freshrss";
        description = "Name of the freshrss database.";
      };

      user = mkOption {
        type = types.str;
        default = "freshrss";
        description = "Name of the freshrss database user.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the user's password file.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.freshrss.enable) {
    services.postgresql = {
      ensureDatabases = [cfg.freshrss.database];
      ensureUsers = [
        {
          name = cfg.freshrss.user;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    # Set password from file if passwordFile is provided
    systemd.services.postgresql.postStart = mkIf (cfg.freshrss.passwordFile != null) (let
      password_file_path = cfg.freshrss.passwordFile;
    in ''
      $PSQL -tA <<'EOF'
        DO $$
        DECLARE password TEXT;
        BEGIN
          password := trim(both from replace(pg_read_file('${password_file_path}'), E'\n', '''));
          EXECUTE format('ALTER ROLE "${cfg.freshrss.database}" WITH PASSWORD '''%s''';', password);
        END $$;
      EOF
    '');

    services.clubcotton.postgresql.postStartCommands = let
      sqlFile = pkgs.writeText "freshrss-setup.sql" ''
        ALTER SCHEMA public OWNER TO "${cfg.freshrss.user}";
      '';
    in [
      ''
        ${lib.getExe' config.services.postgresql.package "psql"} -p ${toString cfg.port} -d "${cfg.freshrss.database}" -f "${sqlFile}"
      ''
    ];
  };
}
