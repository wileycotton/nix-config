{
  config,
  pkgs,
  unstablePkgs,
  ...
}: {
  users.users.tomcotton = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = ["wheel" "docker"]; # Enable ‘sudo’ for the user.
    hashedPassword = "$6$icZo8IyqPlu1YOgc$aRlFcb7dxOOmOebE/hYdLXWPEboyEm5sfBBJZopuRfD1Hu7MQYw0eQokQecb0n5HUgaGXRWMrs2TUqcZMIzC71";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbIFTdml6HkOUMHN7krdP3eIYSPQN6oOGKVu8aA8IVW tomcotton@Toms-MBP.lan"
    ];
    packages = with pkgs; [
      tree
      tmux
      git
      firefox
    ];
  };
}
