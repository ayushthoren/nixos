{ config, pkgs, ... }:
{
  home.packages = [ pkgs.quickshell ];
  services.hyprsunset.enable = true;
  systemd.user.services.hyprsunset.Service.ExecStartPost =
    "${pkgs.coreutils}/bin/env HYPRCTL=${config.wayland.windowManager.hyprland.package}/bin/hyprctl ${pkgs.python3}/bin/python3 ${config.home.homeDirectory}/nixos/modules/home/quickshell/config/utils/display-settings.py restore-night";

  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home/quickshell/config";
}
