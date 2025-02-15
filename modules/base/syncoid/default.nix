{
  config,
  lib,
  ...
}: {
  options.etu.base.syncoid = {
    enable = lib.mkEnableOption "Enable base syncoid settings";
    commands = lib.mkOption {
      default = {};
      description = "services.syncoid.commands to sync";
    };
  };

  config = lib.mkIf config.etu.base.syncoid.enable {
    # Enable syncoid for syncing snapshots.
    services.syncoid = {
      enable = true;
      interval = "*-*-* *:15:00";
      commonArgs = ["--no-sync-snap"];
      sshKey = "/var/lib/syncoid/.ssh/id_ed25519";
      commands = config.etu.base.syncoid.commands;
    };
  };
}
