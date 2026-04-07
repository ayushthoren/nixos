{ inputs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./audio.nix
    ./bootloader.nix
    ./cachyos-kernel.nix
    ./locale.nix
    ./networking.nix
    ./nvidia.nix
    ./ollama.nix
    ./overlays.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
  ];
}