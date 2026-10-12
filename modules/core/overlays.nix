{ inputs, ... }:

{
  nixpkgs.overlays = [    
    # Optimized Hyprland build
    (final: prev:
      let
        hyprlandPackages = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system};
        optimizeHyprland = package: (package.override {
          stdenv = final.stdenvAdapters.useMoldLinker package.stdenv;
        }).overrideAttrs (old: {
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
      if prev.stdenv.hostPlatform.isx86_64 then {
        hyprland = optimizeHyprland hyprlandPackages.hyprland;
        xdg-desktop-portal-hyprland = optimizeHyprland hyprlandPackages.xdg-desktop-portal-hyprland;
      } else { }
    )

    # Optimized quickshell build
    (final: prev: {
      quickshell = (prev.quickshell.override {
        stdenv = final.stdenvAdapters.useMoldLinker prev.stdenv;
      }).overrideAttrs (old: {
        buildInputs = builtins.filter
          (dependency: !(builtins.elem dependency [
            prev.cpptrace
            prev.libxcb
            prev.glib
            prev.polkit
          ]))
          (old.buildInputs or [ ]);

        cmakeFlags = (old.cmakeFlags or [ ]) ++ (with final.lib; [
          (cmakeBool "CRASH_HANDLER" false)
          (cmakeBool "CMAKE_INTERPROCEDURAL_OPTIMIZATION" true)
          (cmakeBool "HYPRLAND_GLOBAL_SHORTCUTS" false)
          (cmakeBool "HYPRLAND_FOCUS_GRAB" false)
          (cmakeBool "HYPRLAND_SURFACE_EXTENSIONS" false)
          (cmakeBool "SCREENCOPY" false)
          (cmakeBool "X11" false)
          (cmakeBool "I3" false)
          (cmakeBool "SERVICE_POLKIT" false)
          (cmakeBool "SERVICE_GREETD" false)
          (cmakeBool "SERVICE_UPOWER" false)
          (cmakeBool "BLUETOOTH" false)
        ]);

        NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
          (old.NIX_CFLAGS_COMPILE or "")
          "-march=x86-64-v3"
          "-mtune=generic"
          "-flto=auto"
          "-ftree-vectorize"
          "-ffast-math"
        ];

        dontStrip = false;
        stripAllList = [ "bin" "lib" ];
      });
    })

    # Pin Kdenlive to avoid a cache miss
    (final: prev:
      let
        kdenlivePkgs = import (builtins.fetchTree {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "f13ff45afd1bb73e640eaa08a7066dbed07e3238";
          narHash = "sha256-zDSUbpoeo/9ZmD2+wXnzxoo1+uhL8vxc0b8yuYMKYq0=";
        }) {
          system = prev.stdenv.hostPlatform.system;
          config = { allowUnfree = true; };
        };
      in {
        kdePackages = prev.kdePackages.overrideScope (kdeFinal: kdePrev: {
          kdenlive = kdenlivePkgs.kdePackages.kdenlive;
        });
      }
    )

    # Rofi from git
    (final: prev: {
      rofi = prev.rofi.override {
        rofi-unwrapped = prev.rofi-unwrapped.overrideAttrs (oldAttrs: {
          src = final.fetchFromGitHub {
            owner = "davatorium";
            repo = "rofi";
            rev = "7575b70967c6ea747ecdeb4e54dc88fbf3939e6d";
            fetchSubmodules = true;
            sha256 = "sha256-wBgVWkrSS5po/J5GzkoAOWrBdW5wjR5MuC0dlGT8dNI=";
          };
          version = "git";
          doInstallCheck = false;
        });
      };
    })

  ];
}
