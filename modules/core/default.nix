{ inputs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./audio.nix
    ./bootloader.nix
    ./kernel
    ./locale.nix
    ./networking.nix
    ./secrets.nix
    ./ssh.nix
    ./nvidia.nix
    ./ollama.nix
    ./overlays.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
  ];
}