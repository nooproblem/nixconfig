let
  # Load niv sources
  sources = import ../../nix/sources.nix;
  nixus = import "${sources.nixus}/default.nix" { };
in
nixus ({ config, ... }: {
  # Set a nixpkgs version for all nodes
  defaults = { ... }: {
    nixpkgs = ../../nix/nixos-unstable;
  };

  nodes.home = { lib, config, ... }: {
    # How to reach this node
    host = "root@192.168.0.146";

    # What configuration it should have
    configuration = ./configuration.nix;
  };

  nodes.sparv = { lib, config, ... }: {
    # How to reach this node
    host = "root@10.5.42.211";

    # What configuration it should have
    configuration = ./configuration.nix;
  };
})
