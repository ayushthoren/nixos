{ pkgs, ... }:
{
  home.packages = [ pkgs.swayosd ];

  xdg.configFile."swayosd/style.css".source = ./style.css;
  xdg.configFile."swayosd/config.toml".source = ./config.toml;
}
