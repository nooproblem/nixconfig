{
  config,
  lib,
  pkgs,
  ...
}: {
  options.etu.development.git.enable = lib.mkEnableOption "Enable development git settings";

  config = lib.mkIf config.etu.development.git.enable {
    # Install git system wide.
    environment.systemPackages = [
      pkgs.git
    ];

    # Configure git for my users home-manager (if it's enabled).
    home-manager.users.${config.etu.user.username} = lib.mkIf config.etu.user.enable {
      home.file = {
        "bin/git-branchclean".source = ../../dotfiles/bin/git-branchclean;
        "bin/git-git".source = ../../dotfiles/bin/git-git;
        "bin/git-lol".source = ../../dotfiles/bin/git-lol;
        "bin/git-refetch-tags".source = ../../dotfiles/bin/git-refetch-tags;
      };

      programs.git = {
        enable = true;

        # Default configs
        extraConfig = {
          commit.gpgSign = config.etu.graphical.gnupg.enable;

          user.name = config.etu.user.realname;
          user.email = config.etu.user.email;
          user.signingKey = config.etu.user.signingKey;

          # Set default "git pull" behaviour so it doesn't try to default to
          # either "git fetch; git merge" (default) or "git fetch; git rebase".
          pull.ff = "only";
        };

        # Global ignores
        ignores = [".ac-php-conf.json"];

        # Conditonally included configs
        includes = [
          {
            condition = "gitdir:/home/${config.etu.user.username}/tvnu/";
            contents = {
              commit.gpgSign = false;
              user.email = config.etu.user.workEmail;
              user.signingKey = "";
            };
          }
        ];
      };
    };
  };
}
