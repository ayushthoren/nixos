{ pkgs, config, ... }:
{
  home.packages = [ pkgs.wlogout ];

  xdg.configFile."wlogout/style.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/wlogout/style.css";
  xdg.configFile."wlogout/layout".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/wlogout/layout";
}