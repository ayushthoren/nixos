{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # Network hostname (can be anything)
  networking.hostName = "nixos";
  
  # Set environment variable to track flake config name
  environment.sessionVariables = {
    NIXOS_FLAKE_HOST = "default";
  };

  # This is a minimal configuration to get a generic system up and running.
  # Add device-specific configurations here as needed to improve compatibility.
  # For example, you may want to add specific GPU drivers or other hardware support based on the components in your system.

  # If you are experiencing lag with Hyprland, uncomment the following line to disable blur and shadow effects:
  # home-manager.users.${username}.hyprland.performanceMode = true;
  
}
