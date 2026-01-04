{
  description = "NixOS + Home Manager setup with Hyprland";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    mediaplayer.url = "./modules/home/waybar/mediaplayer";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, mediaplayer, nix-flatpak, ... } @ inputs:
    let
      system = "x86_64-linux";
      username = "thoren";
      
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/${hostname}/configuration.nix
        ];
        specialArgs = { 
          inherit username inputs; 
        };
      };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        old-laptop = mkHost "old-laptop";
        hybrid-laptop = mkHost "hybrid-laptop";
      };
    };

  # nixConfig = {
  #   substituters = ["https://hyprland.cachix.org"];
  #   trusted-substituters = ["https://hyprland.cachix.org"];
  #   trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  # };
}
