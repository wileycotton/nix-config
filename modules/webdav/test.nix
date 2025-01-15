# nix build '.#checks.x86_64-linux.webdav'
# nix run '.#checks.x86_64-linux.webdav.driverInteractive'
{nixpkgs}: {
  name = "webdav";
  interactive.nodes = let
    testLib = import ../../tests/libtest.nix {};
  in {
    machine = {...}: testLib.mkSshConfig 2223;
  };

  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    imports = [./default.nix];

    services.clubcotton.webdav = {
      enable = true;
      user = "testuser";
      password = "testpass";
      directory = "/var/lib/webdav";
    };

    # Create test directory and file
    systemd.tmpfiles.rules = [
      "d /var/lib/webdav 0755 webdav webdav"
      "f /var/lib/webdav/test.txt 0644 webdav webdav - hello"
    ];
  };

  testScript = ''
    start_all()

    # Wait for webdav service to start
    machine.wait_for_unit("webdav.service")
    machine.wait_for_open_port(8080)

    machine.shell_interact()

    # Test authentication and file access
    machine.succeed(
      "curl -f -u testuser:testpass http://localhost:8080/test.txt | grep hello"
    )

    # Test authentication failure
    machine.fail(
      "curl -f -u wronguser:wrongpass http://localhost:8080/test.txt"
    )

    # Test file upload
    machine.succeed(
      "echo 'new content' > upload.txt",
      "curl -f -u testuser:testpass -T upload.txt http://localhost:8080/upload.txt",
      "curl -f -u testuser:testpass http://localhost:8080/upload.txt | grep 'new content'"
    )
  '';
}
