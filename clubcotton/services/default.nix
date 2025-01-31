{
  lib,
  unstablePkgs,
  ...
}: {
  imports = [
    ./arr
    ./calibre
    ./calibre-web
    ./jellyfin
    ./kavita
    ./navidrome
    ./open-webui
    ./roon-server
    ./sabnzbd
    ./webdav
  ];
}
