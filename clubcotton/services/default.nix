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
    ./roon-server
    ./sabnzbd
    ./webdav
  ];
}
