let
  bcotton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA51nSUvq7WevwvTYzD1S2xSr9QU7DVuYu3k/BGZ7vJ0 bob.cotton@gmail.com";
  users = [bcotton];

  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjeiDeFxI7BcbjDxtPyeWfsUWBW2HKTyjT8/X0719+p root@nixos";
  nix-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQZ30jhjs15gaZkJcKsKXvNqkvgF/rwmKLqcj7rSvCj root@nix-01";
  nix-02 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMVfXXmolLt0FWt5Qw9ihT0XObNM/YKkUZEnjYFEs1Bu root@nix-02";
  nix-03 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUbuIL/nH/8ncAIc8lzzEgvUaT84BtchDmLEQEYTTKC root@nix-03";

  systems = [admin nix-01 nix-02 nix-03];
in {
  "librespot.age".publicKeys = users ++ systems;
  "mopidy.age".publicKeys = users ++ systems;
  "tailscale-keys.env".publicKeys = users ++ systems;
}
