# This module provides Tailscale network service integration
{
  config,
  lib,
  ...
}: with lib; let
  cfg = config.services.clubcotton.tsnsrv;
in {
  options.services.clubcotton.tsnsrv = {
    enable = mkEnableOption "Tailscale network service integration";

    # Authentication key path
    authKeyPath = mkOption {
      type = types.nullOr types.path;
      default = config.age.secrets.tailscale-keys.path;
      description = "Path to the Tailscale auth key.";
    };

    # Service configuration
    services = mkOption {
      type = types.attrsOf (types.submodule ({config, ...}: {
        options = {
          enable = mkEnableOption "service endpoint" // {
            default = true;
          };

          ephemeral = mkOption {
            type = types.bool;
            default = true;
            description = "Whether the node should be ephemeral (auto-removed when stopped).";
          };

          service = mkOption {
            type = types.str;
            description = "NixOS service identifier to proxy (e.g. 'open-webui' for services.open-webui).";
          };

          # Optional override if service uses non-standard host/port config
          portConfig = mkOption {
            type = types.nullOr (types.submodule {
              options = {
                hostPath = mkOption {
                  type = types.str;
                  description = "Config path to host setting (e.g. 'services.open-webui.host').";
                  default = null;
                };
                portPath = mkOption {
                  type = types.str;
                  description = "Config path to port setting (e.g. 'services.open-webui.port').";
                  default = null;
                };
              };
            });
            default = null;
            description = "Override paths to service host/port configuration.";
          };

          # Computed URL based on service configuration
          toURL = mkOption {
            type = types.str;
            description = "URL to forward traffic to (computed from service configuration).";
            default = let
              # Helper function to safely get a value from a config path
              getConfigValue = path: 
                if path == null then null
                else getAttrFromPath (splitString "." path) config;
              
              # Get service configuration
              serviceConfig = let
                # Split service path into parts (e.g., ["open-webui"] or ["clubcotton" "open-webui"])
                parts = splitString "." config.service;
                # Try both direct and nested paths
                directPath = getAttrFromPath ["services" config.service] config;
                nestedPath = getAttrFromPath (["services"] ++ parts) config;
              in
                if directPath != null then directPath
                else if nestedPath != null then nestedPath
                else throw "Service ${config.service} not found in configuration";
              
              # Determine host and port
              host = if config.portConfig != null && config.portConfig.hostPath != null
                    then getConfigValue config.portConfig.hostPath
                    else serviceConfig.host or "localhost";
              
              port = if config.portConfig != null && config.portConfig.portPath != null
                    then getConfigValue config.portConfig.portPath
                    else serviceConfig.port or 3000;
            in
              "http://${toString host}:${toString port}";
          };
        };
      }));
      default = {};
      description = "Service endpoint configurations.";
    };
  };

  config = mkIf cfg.enable {
    # Configure Tailscale network service integration
    services.tsnsrv = {
      enable = config.services.tailscale.enable;
      defaults.authKeyPath = cfg.authKeyPath;
      services = mapAttrs (name: svcConfig: {
        inherit (svcConfig) enable ephemeral toURL;
      }) cfg.services;
    };
  };
}
