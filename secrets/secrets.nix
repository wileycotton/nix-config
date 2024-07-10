let
  bcotton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA51nSUvq7WevwvTYzD1S2xSr9QU7DVuYu3k/BGZ7vJ0 bob.cotton@gmail.com";
  users = [bcotton];

  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjeiDeFxI7BcbjDxtPyeWfsUWBW2HKTyjT8/X0719+p root@nixos";
  nix-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDEJMkba6F8w5b1nDZ3meKEb7PNcWbErBtofbejrIh+ root@nix-01";
  nix-02 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFP84qqvaOkowcYY3B1b96AJ3TPBo0EOlIJuqYQF/AfM root@nix-02";
  nix-03 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUbuIL/nH/8ncAIc8lzzEgvUaT84BtchDmLEQEYTTKC root@nix-03";
  octoprint = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKtxU4yWKvKtZUV82nISi21UCnZ8D2ua8mPMkhk1flNH root@octoprint";
  frigate-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7E24JIWthIHIyTnqjdmJPeGUw8UreinxDNfVq9N2AP root@frigate-host";

  systems = [admin nix-01 nix-02 nix-03 octoprint frigate-host];
in {
  "librespot.age".publicKeys = users ++ systems;
  "mopidy.age".publicKeys = users ++ systems;
  "tailscale-keys.env".publicKeys = users ++ systems;
  "pushover-token.age".publicKeys = users ++ systems;
  "pushover-key.age".publicKeys = users ++ systems;
  "condo-ha-token.age".publicKeys = users ++ systems;
  "homeassistant-token.age".publicKeys = users ++ systems;
  "wireless-config.age".publicKeys = users ++ systems;
  "mqtt.age".publicKeys = users ++ systems;
  "unpoller.age".publicKeys = users ++ systems;
}
