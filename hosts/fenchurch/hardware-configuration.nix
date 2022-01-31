# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=10G" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "zroot/nix";
    fsType = "zfs";
  };

  fileSystems."/persistent" = {
    device = "zroot/persistent";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/persistent/home" = {
    device = "zroot/home";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/var/log" = {
    device = "zroot/var-log";
    fsType = "zfs";
  };

  fileSystems."/var/lib/nzbget-dst" = {
    device = "zroot/var-lib-nzbget-dst";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6241-1BC1";
    fsType = "vfat";
    options = [ "noauto" "x-systemd.automount" ];
  };

  fileSystems."/boot-fallback" = {
    device = "/dev/disk/by-uuid/6258-01A0";
    fsType = "vfat";
    options = [ "noauto" "x-systemd.automount" ];
  };

  fileSystems."/media/zstorage/files" = {
    device = "zstorage/files";
    fsType = "zfs";
    neededForBoot = true;
  };

  # Storage related mounts
  fileSystems."/media/zstorage/files/audio" = {
    device = "zstorage/files/audio";
    fsType = "zfs";
    options = [ "noauto" "x-systemd.automount" ];
  };

  fileSystems."/media/zstorage/files/ebooks" = {
    device = "zstorage/files/ebooks";
    fsType = "zfs";
    options = [ "noauto" "x-systemd.automount" ];
  };

  fileSystems."/media/zstorage/files/software" = {
    device = "zstorage/files/software";
    fsType = "zfs";
    options = [ "noauto" "x-systemd.automount" ];
  };

  fileSystems."/media/zstorage/files/upload" = {
    device = "zstorage/files/upload";
    fsType = "zfs";
    options = [ "noauto" "x-systemd.automount" ];
  };

  fileSystems."/media/zstorage/files/video" = {
    device = "zstorage/files/video";
    fsType = "zfs";
    options = [ "noauto" "x-systemd.automount" ];
  };


  swapDevices = [ ];

  nix.settings.max-jobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
