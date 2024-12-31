{ nixpkgs
, pkgs ? import nixpkgs {}
, lib ? pkgs.lib
, disko
}:

let
  diskoLib = import (disko + "/lib/default.nix") {
    inherit lib;
    makeTest = import (nixpkgs + "/nixos/tests/make-test-python.nix");
    eval-config = import (nixpkgs + "/nixos/lib/eval-config.nix");
  };
  makeDiskoTest = diskoLib.testLib.makeDiskoTest;
  zfsLib = import ./lib.nix { inherit lib; };

  # Test configuration
  testConfig = zfsLib.makeZfsSingleRootConfig {
    poolname = "zroot";
    disk = "/dev/vda";
    swapSize = "2G";
    filesystems = {
      "root" = {
        type = "zfs_fs";
        mountpoint = "/";
        options = {};
      };
      "home" = {
        type = "zfs_fs";
        mountpoint = "/home";
        options = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "true";
        };
      };
    };
  };
in
makeDiskoTest {
  inherit pkgs;
  name = "zfs-single-root";
  disko-config = testConfig;
  extraInstallerConfig = {
    networking.hostId = "8425e349";
  };
  extraTestScript = ''
    def assert_property(ds, property, expected_value):
        out = machine.succeed(f"zfs get -H {property} {ds} -o value").rstrip()
        assert (
            out == expected_value
        ), f"Expected {property}={expected_value} on {ds}, got: {out}"

    # Test ZFS properties
    assert_property("zroot", "compression", "lz4")
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
