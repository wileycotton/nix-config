# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  modulesPath,
  lib,
  ...
}: {
  imports = [
    # Include the default incus configuration.
    # "${modulesPath}/virtualisation/incus-virtual-machine.nix"
    ./hardware-configuration.nix
    # ./disk-config.nix
    ./zfs-mirrored-root.nix
    ./zfs-raidz1.nix
  ];

  time.timeZone = "America/Denver";

  programs.zsh.enable = true;

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA51nSUvq7WevwvTYzD1S2xSr9QU7DVuYu3k/BGZ7vJ0 bob.cotton@gmail.com"
    ];
  };
  services.openssh.enable = true;
  networking.firewall.enable = false;

  networking.hostId = "420cbfd4";
  # boot.loader.systemd-boot.enable = true;

  clubcotton.zfs_mirrored_root = {
    enable = true;
    poolname = "rpool";
    disks = [
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_root"
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_drive1"
    ];
  };

  clubcotton.zfs_raidz1 = {
    enable = true;
    poolname = "ssdpool";
    disks = [
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_nvme1"
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_nvme2"
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_nvme3"
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_nvme4"
    ];
  };

  boot = {
    kernelParams = [
      "boot.shell_on_fail"
    ];

    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = ["nodev"];
            path = "/boot0";
            efiSysMountPoint = "/boot0";
          }
          {
            devices = ["nodev"];
            path = "/boot1";
            efiSysMountPoint = "/boot1";
          }
        ];
      };
    };
  };

  # This is for incus networking
  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-enp5s0" = {
      matchConfig.Name = "enp5s0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig = {
        MACAddress = "40:5b:d6:a8:5b:cb";
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
