{
  pkgs,
  lib,
  config,
  ...
}: {
  launchd.user.agents = lib.mkIf (pkgs.stdenv.isDarwin && config.programs.atuin-config.enable-daemon) {
    atuin-daemon = {
      serviceConfig = {
        ProgramArguments = ["${pkgs.atuin}/bin/atuin" "daemon"];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/atuin-daemon.log";
        StandardErrorPath = "/tmp/atuin-daemon.error.log";
      };
    };
  };
}
