{ config, lib, pkgs, ... }:

{
  imports = [
    ./emacs
    ./fish
    ./htop
    ./nix
    ./tmux
    ./sshd
    ./sanoid
    ./syncoid
    ./spell
  ];

  options.etu.stateVersion = lib.mkOption {
    example = "22.05";
    description = "The NixOS state version to use for this system";
  };

  config = {
    # Enable base services.
    etu.base = {
      emacs.enable = true;
      fish.enable = true;
      htop.enable = true;
      tmux.enable = true;
      nix.enable = true;
      sshd.enable = true;
      sanoid.enable = true;
      spell.enable = true;
    };

    # Set your time zone.
    time.timeZone = "Europe/Stockholm";

    # Select internationalisation properties.
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [
        "all"
      ];
    };

    # Set console font and keymap.
    console.font = "Lat2-Terminus16";
    console.keyMap = "dvorak";

    # Set system state version.
    system.stateVersion = config.etu.stateVersion;

    # Enable doas.
    security.doas.enable = true;

    # Install some command line tools I commonly want available
    environment.systemPackages = [
      # Nice extra command line tools
      pkgs.bat        # "bat - cat with wings", cat|less with language highlight
      pkgs.comma      # the "," command which allows to run non-installed things ", htop"
      pkgs.curl       # curl duh
      pkgs.duf        # nice disk usage output
      pkgs.fd         # find util
      pkgs.file       # file duh
      pkgs.fzf        # fuzzy finder
      pkgs.jc         # parse different formats and command outputs to json
      pkgs.jq         # parse, format and query json documents
      pkgs.ncdu       # disk usage navigator
      pkgs.nix-top    # nix-top is a top for what nix is doing
      pkgs.pv         # pipe viewer for progressbars in pipes
      pkgs.ripgrep    # quick file searcher
      pkgs.testssl    # print TLS certificate info

      # Networking tools
      pkgs.dnsutils   # dig etc
      pkgs.host       # look up host info
      pkgs.whois      # whois duh
      pkgs.prettyping # pretty ping output
      (pkgs.runCommandNoCC "prettyping-pp" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.prettyping}/bin/prettyping $out/bin/pp
      '')

      # Install some color test scripts from xterm
      (pkgs.runCommandNoCC "xterm-color-scripts" { } ''
        tar -xf ${pkgs.xterm.src}

        install -Dm755 xterm-${pkgs.xterm.version}/vttests/256colors2.pl $out/bin/256colors2.pl
        install -Dm755 xterm-${pkgs.xterm.version}/vttests/88colors2.pl $out/bin/88colors2.pl
      '')
    ];

    # Set state version for my users home-manager (if it's enabled).
    home-manager.users.${config.etu.user.username} = lib.mkIf config.etu.user.enable {
      home.stateVersion = config.etu.stateVersion;

      # Install some comand line tools I cummonly want available for
      # my home directory.
      home.packages = [
        pkgs.stow
      ];
    };

    # Set state version for root users home-manager.
    home-manager.users.root.home.stateVersion = config.etu.stateVersion;
  };
}
