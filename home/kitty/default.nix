{ pkgs, config, ... }:
{
  xdg.configFile."kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/kitty/kitty.conf";
  
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 12.0;
    };
  };
}
