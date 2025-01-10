{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  service = "roon-server";
  roonVersion = "2.0-1490";
  roonUrlVersion = builtins.replaceStrings ["." "-"] ["00" "0"] roonVersion;

  cfg = config.services.clubcotton.${service};
  clubcotton = config.clubcotton;
in {
  options.services.clubcotton.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = with pkgs; [
      (self: super: {
        roon-server = super.roon-server.overrideAttrs {
          version = roonVersion;
          src = pkgs.fetchurl {
            url = "https://download.roonlabs.com/updates/production/RoonServer_linuxx64_${roonUrlVersion}.tar.bz2";
            hash = "sha256-WZCSBb7BJWMtfB5zeN0/FNQ4uUYpa79YLSzpLlliWlw=";
          };
        };
      })
    ];
    services.roon-server.enable = true;
  };
}
