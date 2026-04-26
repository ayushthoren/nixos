{ pkgs, inputs, ... }:
let
  hyprlandPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  hyprlandPortalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  # Create a custom sessions directory to prevent the UWSM one from showing up
  myWaylandSessions = pkgs.runCommand "my-wayland-sessions" { } ''
    mkdir -p $out/share/wayland-sessions

    ln -s ${hyprlandPackage}/share/wayland-sessions/hyprland.desktop \
      $out/share/wayland-sessions/hyprland.desktop
  '';
in
{
  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions = "${myWaylandSessions}/share/wayland-sessions";

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
