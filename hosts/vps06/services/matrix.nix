{
  config,
  pkgs,
  matrix-hookshot,
  ...
}: let
  domain = "failar.nu";
in {
  etu.base.zfs.system.directories = [
    # Persistence of synapse data between boots.
    "/var/lib/matrix-synapse"
    "/var/lib/matrix-appservice-irc"
    "/var/lib/matrix-hookshot"
  ];

  services.postgresql = {
    ensureDatabases = ["matrix-synapse"];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensurePermissions."DATABASE \"matrix-synapse\"" = "ALL PRIVILEGES";
      }
    ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/.well-known/matrix/server".extraConfig = let
          server."m.server" = "matrix.${domain}:443";
        in ''
          add_header Content-Type application/json;
          return 200 '${builtins.toJSON server}';
        '';
        "/.well-known/matrix/client".extraConfig = let
          client."m.homeserver".base_url = "https://matrix.${domain}";
        in ''
          add_header Content-Type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON client}';
        '';
        "/_matrix/".return = "307 http://matrix.${domain}$request_uri";
      };
    };
    "element.${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        root = pkgs.element-web.override (_: {
          conf = {
            default_server_config."m.homeserver" = {
              server_name = domain;
              base_url = "https://matrix.${domain}";
            };
            integrations_ui_url = "";
            integgrations_rest_url = "";
            integrations_widgets_urls = [];
            disable_guests = true;
            roomDirectory.servers = [
              domain
              "nixos.org"
              "matrix.org"
            ];
            features = {
              feature_pinning = "labs";
              feature_custom_status = "labs";
              feature_custom_tags = "labs";
              feature_state_counters = "labs";
            };
            showLabsSettings = true;
          };
        });
      };
    };
    "matrix.${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "~* ^(\\/_matrix|\\/_synapse\\/client)" = {
          proxyPass = "http://[::1]:8448";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 900s;
          '';
        };
        "~ ^/_hookshot/(.*)" = {
          proxyPass = "http://127.0.0.1:9000/$1";
          extraConfig = "proxy_set_header X-Forwarded-Ssl on;";
        };
      };
    };
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      # registration_shared_secret = ""; # Set this value to be able
      # to use ${pkgs.matrix-synapse}/bin/register_new_matrix_user
      # like this:
      # $register_new_matrix_user -u [username] -p [password] -a -k [registration_shared_secret] http://localhost:8448.
      server_name = domain;
      public_baseurl = "https://matrix.${domain}";
      database_type = "psycopg2";
      database_args = {
        user = "matrix-synapse";
        database = "matrix-synapse";
        cp_min = 5;
        cp_max = 10;
      };
      report_stats = true;
      enable_metrics = true;
      listeners = [
        {
          type = "metrics";
          port = 9148;
          bind_addresses = ["127.0.0.1"];
          resources = [];
          tls = false;
        }
        {
          bind_addresses = ["::1"];
          port = 8448;
          resources = [
            {
              compress = false;
              names = ["client"];
            }
            {
              compress = false;
              names = ["federation"];
            }
          ];
          tls = false;
          type = "http";
          x_forwarded = true;
        }
      ];
      trusted_key_servers = [
        {
          server_name = "matrix.org";
          verify_keys = {
            "ed25519:auto" = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
          };
        }
      ];
      redaction_retention_period = 1;
      rc_messages_per_second = 10;
      rc_message_burst_count = 15;
      key_refresh_interval = "1h"; # for initial setup so we can invalidate the key earlier
      max_upload_size = "10M";
      url_preview_enabled = false;
      dynamic_thumbnails = true; # might be a nicer user experience?
      allow_guest_access = false;
      enable_registration = false; # for admin purposes
      logConfig = ''
        version: 1
        formatters:
          journal_fmt:
            format: '%(name)s: [%(request)s] %(message)s'
        filters:
          context:
            (): synapse.util.logcontext.LoggingContextFilter
            request: ""
        handlers:
          journal:
            class: systemd.journal.JournalHandler
            formatter: journal_fmt
            filters: [context]
            SYSLOG_IDENTIFIER: synapse
        disable_existing_loggers: True
        loggers:
          synapse:
            level: WARN
          synapse.storage.SQL:
            level: WARN
        root:
          level: WARN
          handlers: [journal]
      '';
      extraConfigFiles = [
        (pkgs.writeText "misc.yml" (builtins.toJSON {
          #session_lifetime = "24h"; # disabled to allow guest accounts
          experimental_features = {spaces_enabled = true;};
        }))
        (pkgs.writeText "retention.yml" (builtins.toJSON {
          retention = {
            enabled = true;
            default_policy = {
              min_lifetime = "1d";
              max_lifetime = "36500d";
            };
            #allowed_lifetime_min = "1d";
            #allowed_lifetime_max = "365d";
            #purge_jobs = [
            #  {
            #    shorted_max_lifetime = "1d";
            #    longest_max_lifetime = "7d";
            #    interval = "5m";
            #  }
            #  {
            #    shorted_max_lifetime = "7d";
            #    longest_max_lifetime = "90d";
            #    interval = "24h";
            #  }
            #];
          };
        }))
        (pkgs.writeText "url-preview.yml" (builtins.toJSON {
          url_preview_enabled = true;
          url_preview_ip_range_blacklist = [
            "127.0.0.0/8"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "100.64.0.0/10"
            "169.254.0.0/16"
            "::1/128"
            "fe80::/64"
            "fc00::/7"
          ];
          url_preview_url_blacklist = [
            {username = "*";}
            {netloc = "google.com";}
            {netloc = "*.google.com";}
            {netloc = "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$";}
          ];
          max_spider_size = "10M";
        }))
        (pkgs.writeText "push.yml" (builtins.toJSON {
          push.include_content = false;
        }))
      ];
      app_service_config_files = [
        "/var/lib/matrix-appservice-irc/registration.yml"
        "/var/lib/matrix-hookshot/registration.yaml"
      ];
    };
  };

  services.matrix-appservice-irc = {
    enable = true;
    registrationUrl = "http://localhost:8009";

    settings = {
      homeserver.url = "https://matrix.${domain}";
      homeserver.domain = domain;

      ircService.servers."irc.beanjuice.me" = {
        name = "beanjuice";
        port = 6697;
        ssl = true;
        sslselfsign = true;
        allowExpiredCerts = true;
        botConfig.enabled = false; # Don't send in a bridge bot
        dynamicChannels.enabled = true; # Allow dynamic joining of channels
        dynamicChannels.aliasTemplate = "#irc_$CHANNEL";
        ircClients.nickTemplate = "$DISPLAY"; # Nick display name: $DISPLAY[m]
        ircClients.allowNickChanges = true;
      };
    };
  };

  systemd.services.matrix-hookshot = let
    registrationFilePath = "/var/lib/matrix-hookshot/registration.yaml";
    configFilePath = "/var/lib/matrix-hookshot/config.yaml";
    passKeyFilePath = "/var/lib/matrix-hookshot/passkey.pem";
  in {
    description = "Matrix-hookshot bridge";
    before = ["matrix-synapse.service"]; # So the registration can be used by Synapse
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    preStart = let
      configJson = {
        bridge.domain = domain;
        bridge.url = "http://localhost:8448";
        bridge.mediaUrl = "https://matrix.${domain}";
        bridge.port = 9993;
        bridge.bindAddress = "127.0.0.1";

        generic.enabled = true;
        generic.urlPrefix = "https://matrix.${domain}/_hookshot/webhook";
        generic.allowJsTransformationFunctions = false;
        generic.waitForComplete = false;
        generic.enableHttpGet = false;
        generic.userIdPrefix = "webhook_";

        passFile = passKeyFilePath;
        metrics.enabled = false;

        logging.level = "info";
        logging.colorize = true;
        logging.json = false;
        logging.timestampFormat = "HH:mm:ss:SSS";

        permissions = [
          {
            actor = "@etu:${domain}";
            services = [
              {
                service = "*";
                level = "admin";
              }
            ];
          }
        ];

        listeners = [
          {
            port = 9000;
            bindAddress = "127.0.0.1";
            resources = ["webhooks"];
          }
        ];
      };

      registrationJson = {
        id = "matrix-hookshot";
        url = "http://127.0.0.1:9993";
        as_token = "'$(${pkgs.pwgen}/bin/pwgen -s 64 -c 1)'";
        hs_token = "'$(${pkgs.pwgen}/bin/pwgen -s 64 -c 1)'";
        sender_localpart = "_hookshot_";
        namespaces.users = [
          {
            exclusive = true;
            regex = "^@webhook_.*:${domain}";
          }
        ];
      };
    in ''
      if ! [ -f "${passKeyFilePath}" ]; then
        ${pkgs.openssl}/bin/openssl genpkey \
          -out "${passKeyFilePath}" \
          -outform PEM \
          -algorithm RSA \
          -pkeyopt rsa_keygen_bits:4096
      fi

      if ! [ -f "${registrationFilePath}" ]; then
        # Generate config file if it doesn't exist
        echo '${builtins.toJSON registrationJson}' | ${pkgs.yq}/bin/yq -y > ${registrationFilePath}
      else
        # Backup id, hs_token and as_token.
        id=$(grep "^id:.*$" ${registrationFilePath})
        hs_token=$(grep "^hs_token:.*$" ${registrationFilePath})
        as_token=$(grep "^as_token:.*$" ${registrationFilePath})

        # Regenerate config file
        echo '${builtins.toJSON registrationJson}' | ${pkgs.yq}/bin/yq -y > ${registrationFilePath}

        # Restore config file
        ${pkgs.gnused}/bin/sed -i "s/^id:.*$/$id/g" ${registrationFilePath}
        ${pkgs.gnused}/bin/sed -i "s/^hs_token:.*$/$hs_token/g" ${registrationFilePath}
        ${pkgs.gnused}/bin/sed -i "s/^as_token:.*$/$as_token/g" ${registrationFilePath}
      fi

      chown matrix-hookshot:matrix-synapse ${registrationFilePath}
      chmod 640 ${registrationFilePath}

      echo '${builtins.toJSON configJson}' | ${pkgs.yq}/bin/yq -y > ${configFilePath}
    '';

    script = "${matrix-hookshot}/bin/matrix-hookshot ${configFilePath} ${registrationFilePath}";
    serviceConfig = {
      User = "matrix-hookshot";
      Group = "matrix-hookshot";
      WorkingDirectory = "/var/lib/matrix-hookshot";

      # Add permissions to chown the registration file
      CapabilityBoundingSet = ["CAP_CHOWN"];
      AmbientCapabilities = ["CAP_CHOWN"];
    };
  };
  users.users.matrix-hookshot = {
    uid = 979;
    group = "matrix-hookshot";
    home = "/var/lib/matrix-hookshot";
    isSystemUser = true;
  };
  users.groups.matrix-hookshot.gid = 979;

  # use mimalloc to improve the memory situation with synapse
  systemd.services.matrix-synapse.environment = {
    LD_PRELOAD = "${pkgs.mimalloc}/lib/libmimalloc.so";
    SYNAPSE_CACHE_FACTOR = "1.0";
    LimitNOFILE = "4096";
  };
}
