{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
, diskoLib ? pkgs.callPackage ../../projects/disko/lib { }
}:
diskoLib.testLib.makeDiskoTest {
  inherit pkgs;
  name = "zfs-single-root";
  disko-config = { lib }: { };  # Empty since we're using the module
  extraInstallerConfig.networking.hostId = "8425e349";
  extraSystemConfig = {
    networking.hostId = "8425e349";
    clubcotton.zfs_single_root = {
      enable = true;
      poolname = "zroot";
      disk = "/dev/vda";
      swapSize = "2G";
      filesystems = {
        "root" = {
          mountpoint = "/";
        };
        "home" = {
          mountpoint = "/home";
          options = {
            compression = "zstd";
            "com.sun:auto-snapshot" = "true";
          };
        };
      };
    };
  };
  extraTestScript = ''
    def assert_property(ds, property, expected_value):
        out = machine.succeed(f"zfs get -H {property} {ds} -o value").rstrip()
        assert (
            out == expected_value
        ), f"Expected {property}={expected_value} on {ds}, got: {out}"

    # Test ZFS properties
    assert_property("zroot", "compression", "zstd")
    assert_property("zroot/home", "compression", "zstd")
    assert_property("zroot/home", "com.sun:auto-snapshot", "true")

    # Test mountpoints
    machine.succeed("mountpoint /")
    machine.succeed("mountpoint /home")
    machine.succeed("mountpoint /boot")

    # Test swap
    machine.succeed("swapon -s | grep /dev/")

    # Test boot loader
    machine.succeed("test -d /boot/loader")
    machine.succeed("test -d /boot/EFI")
  '';
}
