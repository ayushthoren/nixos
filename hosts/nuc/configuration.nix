{ lib, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # Network hostname (can be anything)
  networking.hostName = "nuc";
  
  # Set environment variable to track flake config name
  environment.sessionVariables = {
    NIXOS_FLAKE_HOST = "nuc";
  };

  # Enable Hyprland performance mode (disables blur and shadow)
  home-manager.users.${username}.hyprland.performanceMode = true;

  cachyosKernel.enable = true;

  legacyBootloader = {
    enable = false;
    device = "nodev";
  };

  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
}
