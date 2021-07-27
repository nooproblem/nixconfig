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
    # Import bootloader and related settings for aarch64
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
  ];

  # Disable documentation to make the system smaller.
  documentation.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;
  documentation.man.enable = false;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "22.05";

  # Cross compiling settings.
  nixpkgs.system = "aarch64-linux";

  # Add kernel params for the serial console
  boot.kernelParams = [ "console=ttyS1,115200n8" ];

  # Extra packages.
  environment.systemPackages = with pkgs; [
    file
    htop
  ];

  # Set hostname for system.
  networking.hostName = "nix-star";

  # SSH.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Wifi.
  hardware.enableRedistributableFirmware = true;

  # Passwordless sudo for wheel.
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Enable wireless networking.
  networking.wireless.enable = true;
  networking.wireless.interfaces = [ "wlan0" ];
  networking.wireless.networks.SSID.psk = "PASSWORD";

  # Create users.
  users.mutableUsers = false;
  users.users.nix-star = {
    uid = 1000;
    group = "nix-star";
    isNormalUser = true;
    initialPassword = "hunter2";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = keys.etu.computers;
  };
  users.users.root.openssh.authorizedKeys.keys = keys.etu.computers;
}
