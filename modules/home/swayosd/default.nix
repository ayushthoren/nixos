{ pkgs, config, ... }:
{
  home.packages = [ pkgs.swayosd ];

  xdg.configFile."swayosd/style.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/swayosd/style.css";
  xdg.configFile."swayosd/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/swayosd/config.toml";
}
