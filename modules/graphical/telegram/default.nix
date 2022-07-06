{ config, lib, pkgs, ... }:

{
  options.etu.graphical.telegram.enable = lib.mkEnableOption "Enable graphical telegram settings";

  config = lib.mkIf config.etu.graphical.telegram.enable {
    # Install the telegram chat client.
    environment.systemPackages = [
      pkgs.tdesktop
    ];

    environment.persistence."/persistent" = {
      users.${config.etu.user.username} = {
        directories = [
          ".local/share/TelegramDesktop/tdata"
        ];
      };
    };
  };
}
