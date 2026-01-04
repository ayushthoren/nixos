{ pkgs, ... }:
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    cursorTheme = {
      name = "Breeze";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "Adwaita-Dark";
  };

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.hurmit
    nerd-fonts.arimo
    nerd-fonts.symbols-only
    helvetica-neue-lt-std
  ];
}