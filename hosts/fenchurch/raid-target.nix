{ config, lib, ... }:

{
  config.systemd.targets.cryptraid = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [
      # Containers
      "container@freshrss.service"
      "container@jellyfin.service"
      "container@usenet.service"
      "podman-home-assistant.service"

      "media-legacy.mount"
      "nfs-server.service"
      "systemd-cryptsetup@cryptraid.service"
    ];
  };

  config.systemd.services."container@jellyfin".after = [ "media-legacy.mount" ];
  config.systemd.services."container@usenet".after = [ "media-legacy.mount" ];

  config.systemd.services.nfs-server = {
    wantedBy = lib.mkForce [ "cryptraid.target" ];
    after = [ "media-legacy.mount" ];
  };
}
