{ pkgs, config, ... }:
{
  home.packages = [
    (pkgs.rofi.override {
      plugins = with pkgs; [
        rofi-calc
      ];
    })
  ];

  xdg.configFile."rofi/config.rasi".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/rofi/config.rasi";
}