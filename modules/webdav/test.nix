{nixpkgs}: {
  name = "webdav";

  nodes.machine = {config, pkgs, ...}: {
    imports = [./default.nix];

    services.clubcotton.webdav = {
      enable = true;
      user = "testuser";
      password = "testpass";
      scope = "/var/lib/webdav";
    };

    # Create test directory and file
    systemd.tmpfiles.rules = [
      "d /var/lib/webdav 0755 testuser webdav"
      "f /var/lib/webdav/test.txt 0644 testuser webdav - hello"
    ];
  };

  testScript = ''
    start_all()

    # Wait for webdav service to start
    machine.wait_for_unit("webdav.service")
    machine.wait_for_open_port(8080)

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
