{
  lib,
  unstablePkgs,
  ...
}: {
  imports = [
    ./arr
    ./calibre
    ./calibre-web
    ./freshrss
    ./jellyfin
    ./kavita
    ./navidrome
    ./open-webui
    ./paperless
    ./roon-server
    ./sabnzbd
    ./webdav
  ];
}
