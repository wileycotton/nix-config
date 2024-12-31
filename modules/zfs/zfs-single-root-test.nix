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
  testConfig = {
    disko.devices = zfsLib.makeZfsSingleRootConfig {
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
  };
in
makeDiskoTest {
  inherit pkgs;
  name = "zfs-single-root";
  disko-config = testConfig;
  extraInstallerConfig = {
    networking.hostId = "8425e349";
  };
  extraSystemConfig = {
    networking.hostId = "8425e349";
  };
  extraTestScript = ''
    def assert_property(ds, property, expected_value):
        out = machine.succeed(f"zfs get -H {property} {ds} -o value").rstrip()
        assert (
            out == expected_value
        ), f"Expected {property}={expected_value} on {ds}, got: {out}"

    # Helper function for pool status checks
    def check_pool_status(pool, field, expected):
        status = machine.succeed(f"zpool get -H {field} {pool} -o value").rstrip()
        assert status == expected, f"Expected pool {field} to be {expected}, got: {status}"

    # Test pool health and properties
    check_pool_status("zroot", "health", "ONLINE")
    check_pool_status("zroot", "ashift", "12")
    check_pool_status("zroot", "autotrim", "on")
    check_pool_status("zroot", "delegation", "on")
    check_pool_status("zroot", "multihost", "off")
    check_pool_status("zroot", "readonly", "off")
    check_pool_status("zroot", "autoexpand", "off")

    # Verify dataset structure and properties
    datasets = machine.succeed("zfs list -H -o name").rstrip().split('\n')
    expected_datasets = ["zroot", "zroot/root", "zroot/home"]
    for ds in expected_datasets:
        assert ds in datasets, f"Expected dataset {ds} not found"

    # Test pool features
    features = int(machine.succeed("zpool get all zroot | grep feature@ | grep active | wc -l").strip())
    assert features > 0, "Expected some active features on the pool"

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
