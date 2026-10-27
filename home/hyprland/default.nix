{ lib, config, pkgs, ... }:
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
      brightnessctl
      playerctl
      awww           # Wallpaper daemon
      cliphist       # Clipboard manager
      wl-clipboard   # Wayland clipboard utilities
      hyprshot       # Screenshot tool for Hyprland
      libnotify
    ];

    # Only create performance.lua if performance mode is enabled
    xdg.configFile."hypr/performance.lua" = lib.mkIf config.hyprland.performanceMode {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/hyprland/performance.lua";
    };

    # Imports file that conditionally sources performance.lua
    xdg.configFile."hypr/imports.lua".text =
      if config.hyprland.performanceMode
      then ''require("performance")''
      else "-- Performance mode disabled\n";

    # Use symlink for hyprland.lua
    xdg.configFile."hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/hyprland/hyprland.lua";
    
    # --------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      configType = "lua";
      extraConfig = "--"; # Silence warning
    };
  };
}
