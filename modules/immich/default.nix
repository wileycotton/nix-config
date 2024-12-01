{
  config,
  lib,
  pkgs,
  unstablePkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.immich;
in {

  options.services.clubcotton.immich = {
    enable = mkEnableOption "Immich media server";

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open ports in the firewall for Immich.";
    };

    serverConfig = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "The address Immich server will listen on.";
      };

      port = mkOption {
        type = types.port;
        default = 2283;
        description = "The port Immich server will listen on.";
      };

      mediaLocation = mkOption {
        type = types.str;
        default = "/var/lib/immich";
        description = "Directory where media files will be stored.";
      };

      logLevel = mkOption {
        type = types.enum ["debug" "info" "warn" "error"];
        default = "info";
        description = "Log level for Immich server.";
      };

      externalDomain = mkOption {
        type = types.str;
        default = "";
        description = "External domain for accessing Immich, including http(s)://.";
      };
    };

    database = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable and configure the PostgreSQL database.";
      };

      createDB = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to automatically create the database.";
      };

      name = mkOption {
        type = types.str;
        default = "immich";
        description = "Name of the PostgreSQL database.";
      };

      user = mkOption {
        type = types.str;
        default = "immich";
        description = "PostgreSQL user for Immich.";
      };

      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        description = "PostgreSQL host. Use absolute path for Unix socket.";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port number.";
      };
    };

    redis = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable and configure Redis.";
      };
    };

    machineLearning = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable machine learning features.";
      };

      workers = mkOption {
        type = types.int;
        default = 1;
        description = "Number of machine learning workers.";
      };

      workerTimeout = mkOption {
        type = types.int;
        default = 120;
        description = "Timeout in seconds for machine learning workers.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.immich = {
      enable = true;
      openFirewall = cfg.openFirewall;

      # Server configuration
      host = cfg.serverConfig.host;
      port = cfg.serverConfig.port;
      mediaLocation = cfg.serverConfig.mediaLocation;

      # Database configuration
      database = {
        enable = cfg.database.enable;
        createDB = cfg.database.createDB;
        name = cfg.database.name;
        host = cfg.database.host;
        port = cfg.database.port;
        user = cfg.database.user;
      };

      # Redis configuration
      redis.enable = cfg.redis.enable;

      # Machine learning configuration
      machine-learning = {
        enable = cfg.machineLearning.enable;
        environment = {
          MACHINE_LEARNING_WORKERS = toString cfg.machineLearning.workers;
          MACHINE_LEARNING_WORKER_TIMEOUT = toString cfg.machineLearning.workerTimeout;
        };
      };

      # Basic settings
      settings = {
        newVersionCheck.enabled = false;
        server.externalDomain = cfg.serverConfig.externalDomain;
      };

      # Environment variables
      environment = {
        IMMICH_LOG_LEVEL = cfg.serverConfig.logLevel;
      };
    };

    # PostgreSQL configuration
    services.postgresql = mkIf cfg.database.enable {
      enable = true;
      package = pkgs.postgresql_16;
      extraPlugins = with pkgs.postgresql16Packages; [pgvecto-rs];
      settings = {
        shared_preload_libraries = "vectors.so";
        search_path = "\"$user\", public, vectors";
      };
    };
  };
}
