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
    immich = {
      enable = mkEnableOption "Immich database support";

      database = mkOption {
        type = types.str;
        default = "immich";
        description = "Name of the Immich database.";
      };

      user = mkOption {
        type = types.str;
        default = "immich";
        description = "Name of the Immich database user.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.immich.enable) {
    services.postgresql = {
      ensureDatabases = [cfg.immich.database];
      ensureUsers = [
        {
          name = cfg.immich.user;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
      settings = {
        shared_preload_libraries = ["vectors.so"];
        search_path = "\"$user\", public, vectors";
      };
      extensions = ps: with ps; [pgvecto-rs];
    };

    systemd.services.postgresql.serviceConfig.ExecStartPost = let
      sqlFile = pkgs.writeText "immich-pgvectors-setup.sql" ''
        CREATE EXTENSION IF NOT EXISTS unaccent;
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        CREATE EXTENSION IF NOT EXISTS vectors;
        CREATE EXTENSION IF NOT EXISTS cube;
        CREATE EXTENSION IF NOT EXISTS earthdistance;
        CREATE EXTENSION IF NOT EXISTS pg_trgm;

        ALTER SCHEMA public OWNER TO ${cfg.immich.user};
        ALTER SCHEMA vectors OWNER TO ${cfg.immich.user};
        GRANT SELECT ON TABLE pg_vector_index_stat TO ${cfg.immich.user};

        ALTER EXTENSION vectors UPDATE;
      '';
    in [
      ''
        ${lib.getExe' config.services.postgresql.package "psql"} -d "${cfg.immich.database}" -f "${sqlFile}"
      ''
    ];
  };
}
