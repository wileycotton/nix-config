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
    ./pdfding
    ./roon-server
    ./sabnzbd
    ./webdav
  ];
}
