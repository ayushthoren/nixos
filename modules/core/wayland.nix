{ pkgs, ... }:
let
  hyprlandPackage = pkgs.hyprland;
  hyprlandPortalPackage = pkgs.xdg-desktop-portal-hyprland;

  # Create a custom sessions directory to prevent the UWSM one from showing up
  myWaylandSessions = pkgs.runCommand "my-wayland-sessions" { } ''
    mkdir -p $out/share/wayland-sessions

    ln -s ${hyprlandPackage}/share/wayland-sessions/hyprland.desktop \
      $out/share/wayland-sessions/hyprland.desktop
  '';
in
{
  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings = {
    waylandsessions = "${myWaylandSessions}/share/wayland-sessions";
    session_log = ".local/state/ly-session.log";
  };

  systemd.services.display-manager.serviceConfig = {
    ExecStartPre = [ "${pkgs.procps}/bin/sysctl -w kernel.printk=0" ];
    ExecStopPost = [ "${pkgs.procps}/bin/sysctl -w kernel.printk=4" ];
  };

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    package = hyprlandPackage;
    portalPackage = hyprlandPortalPackage;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}
