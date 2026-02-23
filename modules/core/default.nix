{ inputs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./audio.nix
    ./bootloader.nix
    ./locale.nix
    ./networking.nix
    ./nvidia.nix
    ./overlays.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
  ];
}