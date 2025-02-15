{
  config,
  lib,
  myData,
  pkgs,
  ...
}: {
  options.etu.user = {
    enable = lib.mkEnableOption "Enables my user";
    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 1000;
      description = "My user id for this system.";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "etu";
      description = "My username for this system.";
    };
    realname = lib.mkOption {
      type = lib.types.str;
      default = "Elis Hirwing";
      description = "My realname for this system.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "elis@hirwing.se";
      description = "My email for this system.";
    };
    workEmail = lib.mkOption {
      type = lib.types.str;
      default = "elis.hirwing@schibsted.com";
      description = "My email for this system.";
    };
    signingKey = lib.mkOption {
      type = lib.types.str;
      default = "67FE98F28C44CF221828E12FD57EFA625C9A925F";
      description = "My public signing key for this system.";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    extraAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional authorized keys.";
    };
    extraRootAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional authorized keys for root user.";
    };
    extraUserPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages to install in my users profile.";
    };
    allowEmptyRootPassword = lib.mkEnableOption "If disabled, it will set a root password which requires agenix set up.";
  };

  config = {
    # Immutable users.
    users.mutableUsers = false;

    # Let ~/bin/ be in $PATH
    environment.homeBinInPath = config.etu.user.enable;

    # Load password files.
    age.secrets.hashed-etu-password = lib.mkIf config.etu.user.enable myData.ageModules.hashed-etu-password;
    age.secrets.hashed-root-password = lib.mkIf (!config.etu.user.allowEmptyRootPassword) myData.ageModules.hashed-root-password;

    # Define my user account.
    users.users.${config.etu.user.username} = lib.mkIf config.etu.user.enable {
      description = "${config.etu.user.realname},,,,";
      extraGroups = ["wheel"] ++ config.etu.user.extraGroups;
      passwordFile = config.age.secrets.hashed-etu-password.path;
      isNormalUser = true;
      openssh.authorizedKeys.keys = myData.pubkeys.etu.computers ++ config.etu.user.extraAuthorizedKeys;
      uid = config.etu.user.uid;
    };

    # Define password, authorized keys and shell for root user.
    users.users.root = {
      passwordFile = lib.mkIf (!config.etu.user.allowEmptyRootPassword) config.age.secrets.hashed-root-password.path;
      openssh.authorizedKeys.keys = myData.pubkeys.etu.computers ++ config.etu.user.extraRootAuthorizedKeys;
    };

    # Configure some miscellaneous dotfiles for my user.
    home-manager.users.${config.etu.user.username} = lib.mkIf config.etu.user.enable {
      home.file = {
        # Home nix config.
        ".config/nixpkgs/config.nix".text = "{ allowUnfree = true; }";

        # Nano config
        ".nanorc".text = "set constantshow # Show linenumbers -c as default";

        "bin/restow".source =
          pkgs.runCommand "restow" {
            dataPrefix = config.etu.dataPrefix;
          } ''
            substituteAll ${../dotfiles/bin/restow} $out
            chmod +x $out
          '';
        "bin/spacecolors".source = ../dotfiles/bin/spacecolors;

        "bin/keep".source = pkgs.runCommand "keep" {} ''
          cp ${../dotfiles/bin/keep} $out
          substituteInPlace $out --replace /bin/zsh ${pkgs.zsh}/bin/zsh
        '';
      };

      # Install some comand line tools I cummonly want available for
      # my home directory, as well as extra packages defined by the
      # system or other modules.
      home.packages =
        config.etu.user.extraUserPackages
        ++ [
          pkgs.stow
        ];

      # Set the environment variables.
      home.sessionVariables.EDITOR =
        if config.etu.base.emacs.enable
        then "emacs"
        else "nano";
    };

    # Directories to mount persistent for my user
    etu.base.zfs.user.directories = [
      ".dotfiles"
      ".ssh"
    ];
  };
}
