{ pkgs, config, inputs, ... }:
{
  programs.waybar.enable = true;
  home.packages = [ inputs.mediaplayer.packages.${pkgs.system}.mediaplayer ];

  xdg.configFile."waybar/config.jsonc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/waybar/style.css";
}
