{ pkgs, config, ... }:
{
  home.packages = [ pkgs.hyprlock ];

  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/hyprlock/hyprlock.conf";
}