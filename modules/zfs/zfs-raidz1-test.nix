{
  nixpkgs,
  pkgs ? import nixpkgs {},
  lib ? pkgs.lib,
  disko,
}: let
  diskoLib = import (disko + "/lib/default.nix") {
    inherit lib;
    makeTest = import (nixpkgs + "/nixos/tests/make-test-python.nix");
    eval-config = import (nixpkgs + "/nixos/lib/eval-config.nix");
  };
  makeDiskoTest = diskoLib.testLib.makeDiskoTest;
  zfsLib = import ./lib.nix {inherit lib;};

  # Test configuration combining root filesystem and RAIDZ1 pool
  testConfig = {
    disko.devices =
      lib.recursiveUpdate
      # Root filesystem on single disk
      (zfsLib.makeZfsSingleRootConfig {
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
      })
      # Additional RAIDZ1 pool
      (zfsLib.makeZfsRaidz1Config {
        poolname = "tank";
        disks = ["/dev/vdb" "/dev/vdc" "/dev/vdd" "/dev/vde"];
        datasets = {
          "data" = {
            type = "zfs_fs";
            mountpoint = "/tank/data";
            options = {
              compression = "zstd";
              recordsize = "1M";
            };
          };
          "backup" = {
            type = "zfs_fs";
            mountpoint = "/tank/backup";
            options = {
              compression = "zstd";
              recordsize = "1M";
              copies = "2";
            };
          };
        };
      });
  };
in
  makeDiskoTest {
    inherit pkgs;
    name = "zfs-raidz1";
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

      # Test root pool (zroot)
      check_pool_status("zroot", "health", "ONLINE")
      check_pool_status("zroot", "ashift", "12")
      check_pool_status("zroot", "autotrim", "on")

      # Test RAIDZ1 pool (tank)
      check_pool_status("tank", "health", "ONLINE")
      check_pool_status("tank", "ashift", "12")
      check_pool_status("tank", "autotrim", "on")

      # Verify RAIDZ1 configuration and all components are ONLINE
      status = machine.succeed("zpool status tank")
      assert "raidz1" in status, "Expected RAIDZ1 configuration"

      # Count ONLINE components (pool + raidz1 vdev + 4 drives = 6)
      # Exclude the "state:" line at the top
      online_count = machine.succeed("zpool status tank | grep ONLINE | grep -v state | wc -l").strip()
      assert int(online_count) == 6, f"Expected 6 ONLINE components (pool + raidz1 + 4 drives), got {online_count}"

      # Verify dataset structure and properties
      datasets = machine.succeed("zfs list -H -o name").rstrip().split('\n')
      expected_datasets = [
          "zroot", "zroot/root", "zroot/home",
          "tank", "tank/data", "tank/backup"
      ]
      for ds in expected_datasets:
          assert ds in datasets, f"Expected dataset {ds} not found"

      # Test ZFS properties for root pool
      assert_property("zroot", "compression", "lz4")
      assert_property("zroot/home", "compression", "zstd")
      assert_property("zroot/home", "com.sun:auto-snapshot", "true")

      # Test ZFS properties for RAIDZ1 pool
      assert_property("tank/data", "compression", "zstd")
      assert_property("tank/data", "recordsize", "1M")
      assert_property("tank/backup", "compression", "zstd")
      assert_property("tank/backup", "recordsize", "1M")
      assert_property("tank/backup", "copies", "2")

      # Test mountpoints
      machine.succeed("mountpoint /")
      machine.succeed("mountpoint /home")
      machine.succeed("mountpoint /boot")
      machine.succeed("mountpoint /tank/data")
      machine.succeed("mountpoint /tank/backup")

      # Test swap
      machine.succeed("swapon -s | grep /dev/")

      # Test boot loader
      machine.succeed("test -d /boot/loader")
      machine.succeed("test -d /boot/EFI")
    '';
  }
