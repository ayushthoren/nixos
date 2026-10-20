# Configuration for HP Specre x360 2015 (No dedicated graphics or UEFI support)
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

  legacyBootloader.enable = true;

  # Laptop power/thermal management
  powerManagement.enable = true;
  # services.thermald.enable = true;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        energy_performance_preference = "balance_power";
        turbo = "never";
      };
      charger = {
        governor = "powersave";
        energy_performance_preference = "performance";
        turbo = "auto";
      };
    };
  };
}
