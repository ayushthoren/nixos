{ inputs, username, pkgs, ... }:
{
  nix = {
    optimise.automatic = true;

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
        username
      ];
    };
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    ''
    + builtins.readFile ./caches.conf;
  };

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  documentation.nixos.enable = false;

  # Register the flake in the system registry
  nix.registry.nixos.flake = inputs.self;

  nix.channel.enable = false;

  environment.systemPackages = with pkgs; [
    # NixOS utilities
    nh
    nixpkgs-review
    nixfmt
    nixfmt-tree
  ];
}
