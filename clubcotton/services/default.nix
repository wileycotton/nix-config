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
    ./pdfding
    ./roon-server
    ./sabnzbd
    ./webdav
  ];
}
