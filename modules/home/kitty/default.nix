{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    cava           # Audio visualizer
    cmatrix        # Matrix effect in terminal
    asciiquarium   # Aquarium animation in terminal
  ];

  xdg.configFile."kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/kitty/kitty.conf";
  
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 12.0;
    };
  };
}
