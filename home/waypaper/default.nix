{ pkgs, config, ... }:
{
  home.packages = [ pkgs.waypaper ];

  xdg.configFile."waypaper/config.ini".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/waypaper/config.ini";
}