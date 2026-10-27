{ inputs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./audio.nix
    ./applications.nix
    ./gaming.nix
    ./files.nix
    ./graphics.nix
    ./input.nix
    ./nvidia.nix
    ./wayland.nix
    ./../../overlays
  ];

  services.flatpak.enable = true;

  security.polkit.enable = true;
  hardware.bluetooth.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-40.10.5"
  ];
}
