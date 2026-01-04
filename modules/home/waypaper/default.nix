{ pkgs, ... }:
{
  home.packages = [ pkgs.waypaper ];

  xdg.configFile."waypaper/config.ini".source = ./config.ini;
}