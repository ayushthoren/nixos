{ pkgs, ... }:
{
  home.packages = [
    (pkgs.rofi.override {
      plugins = with pkgs; [
        rofi-calc
      ];
    })
  ];

  xdg.configFile."rofi/config.rasi".source = ./config.rasi;
}