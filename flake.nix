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
      # The following lines are formatted carefully to work with the installation script.
      nixosConfigurations = {
        default = mkHost "default"; # Minimal configuration for generic systems
        desktop = mkHost "desktop"; # Desktop machine with NVIDIA RTX 3060 12GB and AMD Ryzen 7 7800X3D
        spectre = mkHost "spectre"; # 2015 HP Spectre x360 with Intel integrated graphics
        precision = mkHost "precision"; # Dell Precision 5560 with NVIDIA RTX A2000 and Intel integrated graphics
      };
    };
}
