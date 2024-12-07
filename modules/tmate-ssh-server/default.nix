{
  config,
  lib,
  pkgs,
  ...
}: {
  services.tmate-ssh-server = {
    host = "admin";
    enable = true;
    openFirewall = true;
  };
}
