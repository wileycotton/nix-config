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
    ./open-webui
    ./paperless
    ./roon-server
    ./sabnzbd
    ./webdav
  ];
}
