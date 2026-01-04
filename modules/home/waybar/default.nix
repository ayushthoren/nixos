{ pkgs, inputs, ... }:
{
  programs.waybar.enable = true;
  home.packages = [ inputs.mediaplayer.packages.${pkgs.system}.mediaplayer ];

  xdg.configFile."waybar/config.jsonc".source = ./config.jsonc;
  xdg.configFile."waybar/style.css".source = ./style.css;
  xdg.configFile."waybar/power_menu.xml".source = ./power_menu.xml;
}
