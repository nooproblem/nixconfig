# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  # Import my ssh public keys
  keys = import ../../data/pubkeys.nix;
in
{
  imports = [
    # Include the mmdvmhost service.
    ./mmdvmhost/service.nix
  ];

  nixpkgs.overlays = [
    # Add overlay to hack around https://github.com/NixOS/nixpkgs/pull/78430
    # This was suggested in: https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
    (self: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "22.05";

  # Select kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Set up bootloader.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Set log level.
  boot.consoleLogLevel = 7;

  # Serial port settings.
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0" ];

  # Set hostname.
  networking.hostName = "nix-star";

  # Mount filesystems.
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [ "noauto" "x-systemd.automount" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    autoResize = true;
  };

  # Clean /tmp on boot
  boot.cleanTmpDir = true;

  # Firmware for networking.
  hardware.firmware = lib.mkForce [ pkgs.raspberrypiWirelessFirmware ];

  # Disable X libs for a bunch of things.
  environment.noXlibs = true;

  # Disable some things that aren't needed.
  fonts.fontconfig.enable = false;
  powerManagement.enable = false;

  # Disable docs to save time and space.
  documentation.enable = false;

  # Cross compiling settings.
  nixpkgs.system = "aarch64-linux";
  nixpkgs.crossSystem = lib.systems.examples.raspberryPi;

  # Packages to install.
  environment.systemPackages = [
    pkgs.htop pkgs.file
  ];

  # Enable wireless networking.
  networking.wireless.enable = true;
  networking.wireless.interfaces = [ "wlan0" ];
  networking.wireless.networks."SSID".psk = "PASSWORD";

  # Set up users for access.
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "hunter2";
    initialPassword = "hunter2";
    openssh.authorizedKeys.keys = keys.etu.computers;
  };
  users.users.root.openssh.authorizedKeys.keys = keys.etu.computers;

  # Enable OpenSSH out of the box.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Enable the mmdvmhost service.
  services.mmdvmhost.enable = true;
  services.mmdvmhost.settings = {
    General = {
      Callsign = "SA0BSE";
      Id = "2400302";
      Timeout = 240;
      Duplex = 0;
      RFModeHang = 300;
      NetModeHang = 300;
      Display = "OLED";
      Daemon = 1;
    };
    Info = {
      RXFrequency = 433012500;
      TXFrequency = 433012500;
      Latitude = 59.355755;
      Longitude = 17.883849;
      Location = "Stockholm, JO89wi";
      Description = "Sweden";
      URL = "https://sa.0b.se/";
    };
    Modem = {
      Port = "/dev/ttyS0"; # /dev/ttyAMA0
      RXOffset = 7;
      TXOffset = 7;
    };
    DMR = {
      Enable = 1;
      Id = 240030201;
    };
    "DMR Network" = {
      Enable = 1;
      Address = "83.233.234.102";
      Password = "BrandmeisterPassword";
      Slot1 = 0;
    };
    Nextion.ScreenLayout = 0;
    OLED = {
      Scroll = 0;
      LogoScreensaver = 0;
    };
  };
}
