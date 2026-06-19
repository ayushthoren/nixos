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
      awww           # Wallpaper daemon
      cliphist       # Clipboard manager
      wl-clipboard   # Wayland clipboard utilities
      hyprshot       # Screenshot tool for Hyprland
    ];

    # Only create performance.lua if performance mode is enabled
    xdg.configFile."hypr/performance.lua" = lib.mkIf config.hyprland.performanceMode {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/hyprland/performance.lua";
    };

    # Imports file that conditionally sources performance.lua
    xdg.configFile."hypr/imports.lua".text =
      if config.hyprland.performanceMode
      then ''require("performance")''
      else "-- Performance mode disabled\n";

    # Use symlink for hyprland.lua
    xdg.configFile."hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/hyprland/hyprland.lua";
    
    # --------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      configType = "lua";
      extraConfig = "--"; # Silence warning
    };
  };
}
