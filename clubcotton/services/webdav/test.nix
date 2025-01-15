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
    imports = [
      ./default.nix
    ];

    services.clubcotton.webdav = {
      enable = true;
      users = {
        # Full access user
        admin-0 = {
          password = "adminpass0";
          directory = "/var/lib/webdav/admin-0";
          permissions = "CRUD";
        };
        # Other full access user
        admin-1 = {
          password = "adminpass1";
          directory = "/var/lib/webdav/admin-1";
          permissions = "CRUD";
        };
        # Read-only user
        reader = {
          password = "readerpass";
          directory = "/var/lib/webdav/reader";
          permissions = "R";
        };
        
      };
    };

    # Create test directories and files
    systemd.tmpfiles.rules = [
      "d /var/lib/webdav 0755 webdav webdav"
      "d /var/lib/webdav/admin-0 0755 webdav webdav"
      "d /var/lib/webdav/admin-1 0755 webdav webdav"
      "d /var/lib/webdav/reader 0755 webdav webdav"
      "f /var/lib/webdav/admin-0/test.txt 0644 webdav webdav - hello-admin-0"
      "f /var/lib/webdav/admin-1/test.txt 0644 webdav webdav - hello-admin-1"
      "f /var/lib/webdav/reader/test.txt 0644 webdav webdav - hello-reader"
    ];
  };

  testScript = ''
    start_all()

    # Wait for webdav service to start
    machine.wait_for_unit("webdav.service")
    machine.wait_for_open_port(8080)

    machine.shell_interact()

    # Test authentication failures
    machine.fail(
      "curl -f -u wronguser:wrongpass http://localhost:8080/test.txt"
    )

    # Test admin-0 user (CRUD permissions)
    machine.succeed(
      # Read own file
      "curl -f -u admin-0:adminpass0 http://localhost:8080/test.txt | grep hello-admin-0",
      # Create/Update in own directory
      "echo 'new content' > upload.txt",
      "curl -f -u admin-0:adminpass0 -T upload.txt http://localhost:8080/upload.txt",
      "curl -f -u admin-0:adminpass0 http://localhost:8080/upload.txt | grep 'new content'",
      # Delete from own directory
      "curl -f -u admin-0:adminpass0 -X DELETE http://localhost:8080/upload.txt"
    )

    # Test admin-1 user (CRUD permissions)
    machine.succeed(
      # Read own file
      "curl -f -u admin-1:adminpass1 http://localhost:8080/test.txt | grep hello-admin-1",
      # Create/Update in own directory
      "echo 'admin-1 content' > upload.txt",
      "curl -f -u admin-1:adminpass1 -T upload.txt http://localhost:8080/upload.txt",
      "curl -f -u admin-1:adminpass1 http://localhost:8080/upload.txt | grep 'admin-1 content'",
      # Delete from own directory
      "curl -f -u admin-1:adminpass1 -X DELETE http://localhost:8080/upload.txt"
    )

    # Test directory isolation between admin users
    
    # Test relative path access for admin-0
    machine.succeed(
      # Read file using relative path
      "curl -f -u admin-0:adminpass0 http://localhost:8080/../admin-0/test.txt | grep hello-admin-0",
      # Create/Update using relative path
      "echo 'relative path content' > relative.txt",
      "curl -f -u admin-0:adminpass0 -T relative.txt http://localhost:8080/../admin-0/relative.txt",
      "curl -f -u admin-0:adminpass0 http://localhost:8080/../admin-0/relative.txt | grep 'relative path content'",
      # Delete using relative path
      "curl -f -u admin-0:adminpass0 -X DELETE http://localhost:8080/../admin-0/relative.txt"
    )

    machine.fail(
      # admin-0 should not be able to access admin-1's directory
      "curl -f -u admin-0:adminpass0 http://localhost:8080/../admin-1/test.txt",
      # admin-1 should not be able to access admin-0's directory
      "curl -f -u admin-1:adminpass1 http://localhost:8080/../admin-0/test.txt",
      # admin-0 should not be able to write to admin-1's directory
      "echo 'hack' > hack.txt && curl -f -u admin-0:adminpass0 -T hack.txt http://localhost:8080/../admin-1/hack.txt",
      # admin-1 should not be able to write to admin-0's directory
      "echo 'hack' > hack.txt && curl -f -u admin-1:adminpass1 -T hack.txt http://localhost:8080/../admin-0/hack.txt"
    )

    # Test read-only user
    machine.succeed(
      # Read should work
      "curl -f -u reader:readerpass http://localhost:8080/test.txt | grep hello-reader"
    )
    machine.fail(
      # Write should fail
      "echo 'new content' > upload.txt && curl -f -u reader:readerpass -T upload.txt http://localhost:8080/upload.txt",
      # Should not be able to access admin-0's directory
      "curl -f -u reader:readerpass http://localhost:8080/../admin-0/test.txt",
      # Should not be able to access admin-1's directory
      "curl -f -u reader:readerpass http://localhost:8080/../admin-1/test.txt"
    )
  '';
}
