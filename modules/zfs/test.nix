{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
, ...
}:

pkgs.nixosTest {
  name = "zfs-test";

  nodes.machine = { pkgs, modulesPath, ... }: {
    imports = [
      ./zfs-mirrored-root.nix
      ./zfs-raidz1.nix
      (modulesPath + "/profiles/minimal.nix")
      (modulesPath + "/testing/test-instrumentation.nix")
    ];

    # Enable disko
    disko.enable = true;

    # Required for ZFS
    networking.hostId = "deadbeef";
    
    # Create virtual disks for testing
    virtualisation = {
      emptyDiskImages = [ 20 20 20 20 20 20 20 20 ]; # 8 x 20GB disks
      vlans = [ 1 ];
    };

    environment.systemPackages = with pkgs; [
      parted
      gptfdisk
      util-linux
    ];

    # Configure mirrored root setup
    clubcotton.zfs_mirrored_root = {
      enable = true;
      poolname = "rpool";
      disks = [ "/dev/vdb" "/dev/vdc" ];
    };

    # Configure RAIDZ1 setup
    clubcotton.zfs_raidz1 = {
      enable = true;
      poolname = "datapool";
      disks = [ "/dev/vdd" "/dev/vde" "/dev/vdf" "/dev/vdg" ];
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    
    # Test mirrored root pool
    machine.succeed("zpool status rpool")
    machine.succeed("zfs list rpool/local/root")
    machine.succeed("zfs list rpool/local/nix")
    machine.succeed("zfs list rpool/safe/home")
    
    # Verify root pool is mirrored
    result = machine.succeed("zpool status rpool")
    assert "mirror" in result, "Root pool is not mirrored"
    assert "vdb" in result, "vdb not found in root pool"
    assert "vdc" in result, "vdc not found in root pool"
    
    # Test RAIDZ1 data pool
    machine.succeed("zpool status datapool")
    machine.succeed("zfs list datapool/database")
    
    # Verify data pool is RAIDZ1
    result = machine.succeed("zpool status datapool")
    assert "raidz1" in result, "Data pool is not RAIDZ1"
    assert "vdd" in result, "vdd not found in data pool"
    assert "vde" in result, "vde not found in data pool"
    assert "vdf" in result, "vdf not found in data pool"
    assert "vdg" in result, "vdg not found in data pool"
    
    # Test mounting
    machine.succeed("mount | grep -q 'rpool/local/root on / '")
    machine.succeed("mount | grep -q 'rpool/local/nix on /nix '")
    machine.succeed("mount | grep -q 'rpool/safe/home on /home '")
    machine.succeed("mount | grep -q 'datapool/database on /db '")
    
    # Test dataset properties
    machine.succeed("zfs get mountpoint rpool/local/root | grep -q 'legacy'")
    machine.succeed("zfs get atime rpool/local/nix | grep -q 'off'")
    machine.succeed("zfs get com.sun:auto-snapshot rpool/safe/home | grep -q 'true'")
    machine.succeed("zfs get com.sun:auto-snapshot datapool/database | grep -q 'true'")
  '';
}
