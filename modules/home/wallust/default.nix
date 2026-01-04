{ pkgs, ... }:
{
  home.packages = [ pkgs.wallust ];

  xdg.configFile."wallust/wallust.toml".source = ./config.toml;
  xdg.configFile."wallust/templates".source = ./templates;
}