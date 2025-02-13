{
  config,
  pkgs,
  ...
}: {
  # Make sure to have nginx enabled
  services.nginx.enable = true;
  services.nginx.virtualHosts."local.elis.nu".locations = let
    onlyLan = ''
      allow 192.168.1.0/24;
      allow 127.0.0.1/24;
      deny all;
    '';
  in {
    # Index file
    "/" = {
      root = pkgs.writeTextDir "index.html" ''
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <title>Links</title>
          </head>
          <body>
            <ul>
              <li><a href="/bazarr">Bazarr (Subtitles)</a></li>
              <li><a href="/sonarr">Sonarr (Series)</a></li>
              <li><a href="/radarr">Radarr (Movies)</a></li>
              <li><a href="/lidarr">Lidarr (Music)</a></li>
              <li><a href="/nzbget">NzbGet</a></li>
            </ul>
          </body>
        </html>
      '';
      extraConfig = onlyLan;
    };
    "/bazarr" = {
      proxyPass = "http://127.0.0.1:6767/bazarr";
      extraConfig = onlyLan;
    };
    "/sonarr" = {
      proxyPass = "http://127.0.0.1:8989/sonarr";
      extraConfig = onlyLan;
    };
    "/radarr" = {
      proxyPass = "http://127.0.0.1:7878/radarr";
      extraConfig = onlyLan;
    };
    "/lidarr" = {
      proxyPass = "http://127.0.0.1:8686/lidarr";
      extraConfig = onlyLan;
    };
    "~ ^/nzbget($|./*)" = {
      proxyPass = "http://127.0.0.1:6789";
      extraConfig =
        onlyLan
        + ''
          rewrite /nzbget/(.*) /$1 break;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
    };
  };

  # Enable usenet related services in a container
  containers.usenet = {
    autoStart = true;
    config = {
      lib,
      pkgs,
      ...
    }: {
      # The NixOS release to be compatible with for stateful data such as databases.
      system.stateVersion = config.etu.stateVersion;

      # Disable documentation to make the system smaller.
      documentation.enable = false;
      documentation.doc.enable = false;
      documentation.info.enable = false;
      documentation.man.enable = false;

      # nzbget needs unrar
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["unrar"];

      services.bazarr = {
        enable = true;
        user = "downloads";
        group = "downloads";
      };
      services.sonarr = {
        enable = true;
        user = "downloads";
        group = "downloads";
      };
      services.radarr = {
        enable = true;
        user = "downloads";
        group = "downloads";
      };
      services.lidarr = {
        enable = true;
        user = "downloads";
        group = "downloads";
      };
      services.nzbget = {
        enable = true;
        user = "downloads";
        group = "downloads";
      };

      users.users.downloads = {
        group = "downloads";
        uid = 947;
        isSystemUser = true;
      };
      users.groups.downloads.gid = 947;
    };

    bindMounts = {
      bazarr = {
        mountPoint = "/var/lib/bazarr";
        hostPath = "${config.etu.dataPrefix}/var/lib/bazarr";
        isReadOnly = false;
      };
      sonarr = {
        mountPoint = "/var/lib/sonarr/.config/NzbDrone";
        hostPath = "${config.etu.dataPrefix}/var/lib/sonarr";
        isReadOnly = false;
      };
      radarr = {
        mountPoint = "/var/lib/radarr/.config/Radarr";
        hostPath = "${config.etu.dataPrefix}/var/lib/radarr";
        isReadOnly = false;
      };
      lidarr = {
        mountPoint = "/var/lib/lidarr/.config/Lidarr";
        hostPath = "${config.etu.dataPrefix}/var/lib/lidarr";
        isReadOnly = false;
      };
      nzbget = {
        mountPoint = "/var/lib/nzbget";
        hostPath = "${config.etu.dataPrefix}/var/lib/nzbget";
        isReadOnly = false;
      };
      nzbget-dst = {
        mountPoint = "/var/lib/nzbget-dst";
        hostPath = "/var/lib/nzbget-dst";
        isReadOnly = false;
      };
      media = {
        mountPoint = "/media";
        hostPath = "/media/zstorage/files";
        isReadOnly = false;
      };
    };
  };
}
