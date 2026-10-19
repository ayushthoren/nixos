{ config, ... }:
{
  xdg.configFile."mango/config.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/mango/config.conf";
}
