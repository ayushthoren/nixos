# Configuration for HP Spectre x360 2015 (13-4102dx)
{ username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # Network hostname (can be anything)
  networking.hostName = "spectre";
  
  # Enable Hyprland performance mode (disables blur and shadow)
  home-manager.users.${username}.hyprland.performanceMode = true;
  
  # Set environment variable to track flake config name
  environment.sessionVariables = {
    NIXOS_FLAKE_HOST = "spectre";
  };

  cachyosKernel.enable = true;
  secrets.enable = true;

  # Laptop power/thermal management
  powerManagement.enable = true;
  services.thermald.enable = true;

  # Disable turbo
  systemd.tmpfiles.rules = [ "w /sys/devices/system/cpu/intel_pstate/no_turbo - - - - 1" ];

  # Improve Synaptics touchpad handling
  boot.extraModprobeConfig = "options psmouse synaptics_intertouch=1";
}
