{ config, pkgs, ... }:
{
  home.stateVersion = "25.05";

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GDK_BACKEND = "wayland,x11";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
    NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    # Keep various program files out of the home directory
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/compose";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
  };
}
