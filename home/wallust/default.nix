{ pkgs, config, ... }:
{
  home.packages = [ pkgs.wallust ];

  xdg.configFile."wallust/wallust.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/wallust/config.toml";
  xdg.configFile."wallust/templates".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/wallust/templates";
}