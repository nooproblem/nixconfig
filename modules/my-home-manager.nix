{ config, lib, pkgs, ... }:
let
  cfg = config.my.home-manager;

  swayEnabled = config.my.sway.enable;

  # Load sources
  sources = import ../nix/sources.nix;
in
{
  imports = [
    # Import the home-manager module
    "${sources.home-manager}/nixos"

    # Import home-manager configurations
    ./home-manager.d/emacs.nix
    ./home-manager.d/htop.nix
    ./home-manager.d/sway.nix
  ];

  config = lib.mkIf cfg.enable {
    # Make sure to start the home-manager activation before I log it.
    systemd.services."home-manager-${config.my.user.username}" = {
      before = [ "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    home-manager.users.${config.my.user.username} = {
        # Import a persistance module for home-manager.
        imports = [
          ./home-manager/weechat.nix
        ];

        programs.home-manager.enable = true;

        home.file = {
          # Home nix config.
          ".config/nixpkgs/config.nix".text = "{ allowUnfree = true; }";

          # Nano config
          ".nanorc".text = "set constantshow # Show linenumbers -c as default";

          # Tmux config
          ".tmux.conf".source = ./dotfiles/tmux.conf;

          # Fish config
          ".config/fish/config.fish".source = ./dotfiles/fish/config.fish;

          # Fish functions
          ".config/fish/functions".source = ./dotfiles/fish/functions;

          # Lorrirc
          ".direnvrc".text = ''
            use_nix() {
              eval "$(lorri direnv)"
            }
          '';

          # Some extra scripts
          "bin/git-branchclean".source = ./dotfiles/bin/git-branchclean;
          "bin/git-git".source = ./dotfiles/bin/git-git;
          "bin/git-lol".source = ./dotfiles/bin/git-lol;
          "bin/git-refetch-tags".source = ./dotfiles/bin/git-refetch-tags;
          "bin/restow".source = ./dotfiles/bin/restow;
          "bin/spacecolors".source = ./dotfiles/bin/spacecolors;

          "bin/keep".source = pkgs.runCommandNoCC "keep" { } ''
            cp ${./dotfiles/bin/keep} $out
            substituteInPlace $out --replace /bin/zsh ${pkgs.zsh}/bin/zsh
          '';
        };

        programs.git = {
          enable = true;

          # Default configs
          extraConfig = {
            commit.gpgSign = swayEnabled;

            user.name = config.my.user.realname;
            user.email = config.my.user.email;
            user.signingKey = config.my.user.signingKey;

            # Set default "git pull" behaviour so it doesn't try to default to
            # either "git fetch; git merge" (default) or "git fetch; git rebase".
            pull.ff = "only";
          };

          # Global ignores
          ignores = [ ".ac-php-conf.json" ];

          # Conditonally included configs
          includes = [{
            condition = "gitdir:/home/${config.my.user.username}/tvnu/";
            contents = {
              commit.gpgSign = false;
              user.email = config.my.user.workEmail;
              user.signingKey = "";
            };
          }];
        };

        # Enable weechat configuration
        programs.weechat.enable = (config.networking.hostName == "vps04");
        programs.weechat.scripts = with pkgs.weechatScripts; [
          colorize_nicks
          weechat-matrix

          (pkgs.stdenv.mkDerivation {
            pname = "zerotab";
            version = "1.5";
            src = pkgs.fetchurl {
              url = "https://github.com/weechat/scripts/raw/dff455a80e065ad2131cf6cab190821b4ec415a3/python/zerotab.py";
              sha256 = "1qp3h8kd35m8ywskizpgcs53kdj7y1qm0y9kcy9wjvhny0g35p4y";
            };
            dontUnpack = true;
            passthru.scripts = [ "zerotab.py" ];
            installPhase = ''
              install -D $src $out/share/zerotab.py
            '';
          })

          (pkgs.stdenv.mkDerivation {
            pname = "title";
            version = "0.9";
            src = pkgs.fetchurl {
              url = "https://github.com/weechat/scripts/raw/1ec7ba80f5fec074c86b5e2054537e5f94fde1a7/python/title.py";
              sha256 = "1h8mxpv47q3inhynlfjm3pdjxlr2fl06z4cdhr06kpm8f7xvz56p";
            };
            dontUnpack = true;
            passthru.scripts = [ "title.py" ];
            installPhase = ''
              install -D $src $out/share/title.py
            '';
          })

          (pkgs.stdenv.mkDerivation {
            pname = "screen_away";
            version = "0.16";
            src = pkgs.fetchurl {
              url = "https://github.com/weechat/scripts/raw/08f39d6892b0f2d0d14e270424be80ffdc870e9d/python/screen_away.py";
              sha256 = "1m48n23vv48adb2p8zcvvnk5qwl8h249v0nmdrn8zajkhgprjywp";
            };
            dontUnpack = true;
            passthru.scripts = [ "screen_away.py" ];
            installPhase = ''
              install -D $src $out/share/screen_away.py
            '';
          })

          (pkgs.stdenv.mkDerivation {
            pname = "chanop";
            version = "0.3.4";
            src = pkgs.fetchurl {
              url = "https://github.com/weechat/scripts/raw/08f39d6892b0f2d0d14e270424be80ffdc870e9d/python/chanop.py";
              sha256 = "0d84dcsbywxh5cdbq9bbgr7afjm9mm99lhz8fhl8fcnhdji8mr6p";
            };
            dontUnpack = true;
            passthru.scripts = [ "chanop.py" ];
            installPhase = ''
              install -D $src $out/share/chanop.py
            '';
          })

          (pkgs.stdenv.mkDerivation {
            pname = "nickregain";
            version = "1.1.1";
            src = pkgs.fetchurl {
              url = "https://github.com/weechat/scripts/raw/d1b288d3c49b5e6deb14f61f0acaf25aecc24fdb/perl/nickregain.pl";
              sha256 = "0m5hdlzyl1xh61zh87lhjjpz6kdgjm3h651s5mlmhs8n2ff3mnjw";
            };
            dontUnpack = true;
            passthru.scripts = [ "nickregain.pl" ];
            installPhase = ''
              install -D $src $out/share/nickregain.pl
            '';
          })

          (pkgs.stdenv.mkDerivation {
            pname = "recoverop";
            version = "0.1.2";
            src = pkgs.fetchurl {
              url = "https://github.com/weechat/scripts/raw/396c12c65c8667dac15354d4b4b2f0f2a4183fdc/perl/recoverop.pl";
              sha256 = "17ccxfzcms37ypb8w2fb7kpjxgrxmdkq8jml0q0qby1a2gky7iyz";
            };
            dontUnpack = true;
            passthru.scripts = [ "recoverop.pl" ];
            installPhase = ''
              install -D $src $out/share/recoverop.pl
            '';
          })
        ];
        programs.weechat.configs = {
          alias.cmd = {
            # Unset default aliases
            AAWAY = null;  ANICK = null;   BEEP = null; BYE = null;   C = null;
            CL = null;     CLOSE = null;   CHAT = null; EXIT = null;  IG = null;
            J = null;      K = null;       KB = null;   LEAVE = null; M = null;
            MSGBUF = null; MUB = null;     N = null;    Q = null;     REDRAW = null;
            SAY = null;    SIGNOFF = null; T = null;    UB = null;    UMODE = null;
            V = null;      W = null;       WC = null;   WI = null;    WII = null;
            WM = null;     WW = null;

            # Set my own aliases
            anick = "allserv /nick";
            bail = "/me bailar";
            clear = "buffer clear";
            close = "buffer close";
            exit = "quit";
            j = "join";
            n = "names";
            q = "query";
            t = "topic";
            # This one doesn't work, it cuts of after the first ;
            # weeclear = "anick etu; buffer weechat; allserv /buffer clear; buffer clear; version; uptime; buffer close relay.relay.list";
          };
          irc.server_default.nicks = [ "etu" "etu_" "_etu" "_etu_" ];
          irc.server_default.username = "etu";
          irc.server = {
            beanjuice = {
              addresses = "irc.beanjuice.me/6697";
              autoconnect = true;
              autojoin = "#vikings";
              ssl = true;
              ssl_verify = false;
            };
            efnet = {
              addresses = [ "irc.swepipe.se/6697" "efnet.port80.se/6697" "efnet.xs4all.nl/6697" ];
              autoconnect = true;
              autojoin = "#mellovision";
              ssl = true;
              ssl_verify = false;
            };
            geekshed = {
              addresses = "irc.geekshed.net/6697";
              ssl = true;
              autoconnect = true;
              autojoin = "#jupiterbroadcasting";
            };
            hackint = {
              addresses = "irc.eu.hackint.org/6697";
              autoconnect = true;
              autojoin = "#tvl";
              sasl_mechanism = "plain";
              sasl_password = ''''${sec.hackint.password}'';
              sasl_username = "etu";
              ssl = true;
            };
            oftc = {
              addresses = "irc.oftc.net/6697";
              autoconnect = true;
              autojoin = [ "#flummon" "#ix" ];
              ssl = true;
              ssl_cert = "%h/ssl/etu.pem";
              ssl_verify = true;
            };
          };
          logger.file.auto_log = false;
          relay.network.password = ''''${sec.relay.password}'';
          relay.port.weechat = 8001;
          colorize_nicks.look.colorize_input = true;
          weechat = {
            look.item_time_format = "%H:%M:%S";
            look.prefix_suffix = "|";
            look.read_marker_string = "=";
            look.read_marker_always_show = true;
            look.nick_completer = ": ";
            look.chat_read_marker = "darkgray";
            look.chat_inactive_buffer = "darkgray";
            look.chat_time_delimiters = "default"; # Default is "brown"
          };
        };

        home.stateVersion = "20.09";
      };
  };
}
