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
      source = ./performance.conf;
    };

    # Copy hyprland.conf and optionally append performance.conf source line
    xdg.configFile."hypr/hyprland.conf".text = 
      let
        baseConfig = builtins.readFile ./hyprland.conf;
        performanceImport = "\nsource = ~/.config/hypr/performance.conf";
      in
      if config.hyprland.performanceMode
      then baseConfig + performanceImport
      else baseConfig;
    
    # --------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };
}