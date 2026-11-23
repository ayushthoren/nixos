{ inputs, ... }:
{
  nixpkgs.overlays = [
    (import ./optimized/hyprland.nix { inherit inputs; })
    (import ./optimized/quickshell.nix)
    (import ./fixes/kdenlive.nix)
    (import ./fixes/rofi.nix)
    (import ./fixes/vesktop.nix)
  ];
}
