# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, ... }:
let
  # Load secrets
  secrets = import ../../data/load-secrets.nix;
in
{
  imports = [
    # Include hardware quirks
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t495

    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./persistence.nix

    # Import local modules
    ../../modules
  ];

  config = {
    # The NixOS release to be compatible with for stateful data such as databases.
    system.stateVersion = "21.03";

    # Set hostname
    networking.hostName = "agrajag";

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_5_9;

    # Settings needed for ZFS
    boot.supportedFilesystems = [ "zfs" ];
    networking.hostId = "27416952";
    services.zfs.autoScrub.enable = true;
    services.zfs.autoSnapshot.enable = true;

    # Use nix with flakes support
    nix.package = pkgs.nixFlakes;
    nix.extraOptions = "experimental-features = nix-command flakes";

    # Set nixpkgs to NIX_PATH to ease the transaction to flakes.
    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    # Hardware settings
    hardware.enableRedistributableFirmware = true;

    # Include udev rules to give permissions to the video group to change
    # backlight using acpilight.
    hardware.acpilight.enable = true;

    # Set video driver
    services.xserver.videoDrivers = [ "modesetting" ];

    # Enable fwupd for firmware updates etc
    services.fwupd.enable = true;

    # Enable bluetooth
    hardware.bluetooth.enable = true;

    # Enable CUPS to print documents.
    services.printing.enable = true;
    services.printing.drivers = [
      pkgs.postscript-lexmark
    ];

    # Enable printer configuration
    hardware.printers.ensureDefaultPrinter = "Lexmark_CS510de";
    hardware.printers.ensurePrinters = [
      {
        name = "Lexmark_CS510de";
        deviceUri = "ipps://192.168.0.124:443/ipp/print";
        model = "postscript-lexmark/Lexmark-CS510_Series-Postscript-Lexmark.ppd";
        location = "UFS";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];

    # Enable SANE to handle scanners
    hardware.sane.enable = true;

    # Disable root login for ssh
    services.openssh.permitRootLogin = "no";

    # Enable common cli settings for my systems
    my.common-cli.enable = true;

    # Enable aspell and hunspell with dictionaries.
    my.spell.enable = true;

    # Enable gpg related stuff
    my.gpg-utils.enable = true;

    # Enable common graphical stuff
    my.common-graphical.enable = true;

    # Enable emacs
    my.emacs.enable = true;
    my.emacs.package = "wayland";

    # Enable sway
    my.sway.enable = true;

    # Define a user account.
    my.user.enable = true;
    my.user.extraGroups = [ "video" "docker" "libvirtd" ];

    # Immutable users due to tmpfs
    users.mutableUsers = false;

    # Set passwords
    users.users.root.initialHashedPassword = secrets.hashedRootPassword;
    users.users.etu.initialHashedPassword = secrets.hashedEtuPassword;

    # Home-manager as nix module
    my.home-manager.enable = true;

    # Set up docker
    virtualisation.docker.enable = true;

    # Set up virt-manager
    virtualisation.libvirtd.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [ virt-manager ];
  };
}
