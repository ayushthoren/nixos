{ inputs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./audio.nix
    ./bootloader.nix
    ./locale.nix
    ./networking.nix
    ./overlays.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
  ];
}