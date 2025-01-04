{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.vnc;
in {
  options.services.clubcotton.vnc = {
    enable = mkEnableOption "vnc";
  };

  config = mkIf cfg.enable {
    systemd.sockets.terminal-server = {
      description = "Terminal Server Socket";
      wantedBy = ["sockets.target"];
      before = ["multi-user.target"];
      socketConfig.Accept = true;
      socketConfig.ListenStream = 5900;
    };

    systemd.services."terminal-server@" = {
      description = "Terminal Server";

      path = [
        pkgs.xorg.xorgserver.out
        pkgs.gawk
        pkgs.which
        pkgs.openssl
        pkgs.xorg.xauth
        pkgs.nettools
        pkgs.shadow
        pkgs.procps
        pkgs.util-linux
        pkgs.bash
      ];

      environment.FD_GEOM = "1024x786x24";
      environment.FD_XDMCP_IF = "127.0.0.1";
      #environment.FIND_DISPLAY_OUTPUT = "/tmp/foo"; # to debug the "find display" script

      serviceConfig = {
        StandardInput = "socket";
        StandardOutput = "socket";
        StandardError = "journal";
        ExecStart = "@${pkgs.x11vnc}/bin/x11vnc x11vnc -inetd -display WAIT:1024x786:cmd=FINDCREATEDISPLAY-Xvfb.xdmcp -noipv6 -ncache 0 -unixpw -shared";

        # Don't kill the X server when the user quits the VNC
        # connection.  FIXME: the X server should run in a
        # separate systemd session.
        KillMode = "process";
      };
    };

    services.xrdp.enable = true;
  };
}
