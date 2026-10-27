# Optimized Hyprland build
{ inputs }:
final: prev:
let
  hyprlandPackages = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system};
  optimizeHyprland =
    package:
    (package.override {
      stdenv = final.stdenvAdapters.useMoldLinker package.stdenv;
    }).overrideAttrs
      (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          (prev.lib.cmakeBool "CMAKE_INTERPROCEDURAL_OPTIMIZATION" true)
        ];

        NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
          (old.NIX_CFLAGS_COMPILE or "")
          "-O3"
          "-march=x86-64-v3"
          "-mtune=generic"
          "-flto=auto"
          "-fno-plt"
          "-fomit-frame-pointer"
        ];

        NIX_LDFLAGS = builtins.concatStringsSep " " [
          (old.NIX_LDFLAGS or "")
          "-flto=auto"
        ];
      });
in
if prev.stdenv.hostPlatform.isx86_64 then
  {
    hyprland = optimizeHyprland hyprlandPackages.hyprland;
    xdg-desktop-portal-hyprland = optimizeHyprland hyprlandPackages.xdg-desktop-portal-hyprland;
  }
else
  { }
