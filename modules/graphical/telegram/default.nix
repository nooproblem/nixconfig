{ config, lib, pkgs, ... }:

{
  options.etu.graphical.telegram.enable = lib.mkEnableOption "Enable graphical telegram settings";

  config = lib.mkIf config.etu.graphical.telegram.enable {
    # Install the telegram chat client.
    home-manager.users.${config.etu.user.username} = lib.mkIf config.etu.user.enable {
      home.packages = [
        pkgs.tdesktop
      ];
    };

    # Enable persistence for telegram files.
    etu.base.zfs.user.directories = [
      ".local/share/TelegramDesktop/tdata"
    ];
  };
}
