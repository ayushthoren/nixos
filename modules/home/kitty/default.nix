{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cava     # Audio visualizer
    cmatrix  # Matrix effect in terminal
  ];

  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 12.0;
    };
  };
}
