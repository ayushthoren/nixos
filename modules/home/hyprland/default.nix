{ lib, config, inputs, pkgs, ... }:
{
  options = {
    hyprland.performanceMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable performance mode (disables blur and shadow)";
    };
  };

  config = {
    # Hyprland-related packages
    home.packages = with pkgs; [
      swww           # Wallpaper daemon
      cliphist       # Clipboard manager
      wl-clipboard   # Wayland clipboard utilities
      hyprshot       # Screenshot tool for Hyprland
    ];

    # Only create performance.conf if performance mode is enabled
    xdg.configFile."hypr/performance.conf" = lib.mkIf config.hyprland.performanceMode {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/hyprland/performance.conf";
    };

    # Imports file that conditionally sources performance.conf
    xdg.configFile."hypr/imports.conf".text = 
      if config.hyprland.performanceMode
      then "source = ~/.config/hypr/performance.conf"
      else "# Performance mode disabled";

    # Use symlink for hyprland.conf
    xdg.configFile."hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/hyprland/hyprland.conf";
    
    # --------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      extraConfig = "#"; # Silence warning
    };
  };
}