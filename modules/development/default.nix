{ config, lib, ... }:

{
  imports = [
    ./git
  ];

  options.etu.development.enable = lib.mkEnableOption "Enable development settings";

  config = lib.mkIf config.etu.development.enable {
    etu = {
      development.git.enable = true;
    };
  };
}
