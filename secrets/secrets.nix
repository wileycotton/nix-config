let
  bcotton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA51nSUvq7WevwvTYzD1S2xSr9QU7DVuYu3k/BGZ7vJ0 bob.cotton@gmail.com";
  users = [ bcotton ];
in
{
  "spotify.age".publicKeys = [ bcotton ];
  "spotify-client-id.age".publicKeys = [ bcotton ];
  "spotify-client-secret.age".publicKeys = [ bcotton ];
}