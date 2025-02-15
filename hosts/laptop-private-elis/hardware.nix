{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Configure boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = ["nvme" "ehci_pci" "xhci_pci" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];

  boot.kernelModules = ["kvm-amd"];

  # Install thinkpad modules for TLP.
  boot.extraModulePackages = with config.boot.kernelPackages; [acpi_call];

  # Set kernel.
  boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;

  # Enable a nice boot splash screen.
  boot.initrd.systemd.enable = true; # needed for ZFS password prompt with plymouth.
  boot.plymouth.enable = true;

  # Enable ZFS.
  boot.supportedFilesystems = ["zfs"];

  # Enable ZFS scrubbing.
  services.zfs.autoScrub.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Install firmware for hardware.
  hardware.enableRedistributableFirmware = true;

  # Include udev rules to give permissions to the video group to change
  # backlight using acpilight.
  hardware.acpilight.enable = true;

  # Set video driver.
  services.xserver.videoDrivers = ["modesetting"];

  # Enable fwupd for firmware updates etc.
  services.fwupd.enable = true;

  # Enable TLP.
  services.tlp.enable = true;
  services.tlp.settings.START_CHARGE_THRESH_BAT0 = 40;
  services.tlp.settings.STOP_CHARGE_THRESH_BAT0 = 70;

  # Filesystem mounts.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=3G" "mode=755"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D646-84B5";
    fsType = "vfat";
    options = ["defaults" "noexec" "noauto" "x-systemd.automount"];
  };

  fileSystems."/nix" = {
    device = "zroot/local/nix";
    fsType = "zfs";
  };

  fileSystems.${config.etu.dataPrefix} = {
    device = "zroot/safe/data";
    fsType = "zfs";
    neededForBoot = true;
    options = ["defaults" "noexec"];
  };

  fileSystems."${config.etu.dataPrefix}/home" = {
    device = "zroot/safe/home";
    fsType = "zfs";
    neededForBoot = true;
    options = ["defaults" "noexec"];
  };

  fileSystems."/var/log" = {
    device = "zroot/local/var-log";
    fsType = "zfs";
    options = ["defaults" "noexec"];
  };

  # Bind mount for persistent libvirt state.
  etu.base.zfs.system.directories = [
    "/var/lib/libvirt"
  ];

  # Swap devices.
  swapDevices = [];

  # Set max jobs in nix.
  nix.settings.max-jobs = lib.mkDefault 8;

  # Set CPU Frequency Governor.
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
