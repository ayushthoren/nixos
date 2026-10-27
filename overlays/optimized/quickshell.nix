# Optimized quickshell build
final: prev: {
  quickshell =
    (prev.quickshell.override {
      stdenv = final.stdenvAdapters.useMoldLinker prev.stdenv;
    }).overrideAttrs
      (old: {
        buildInputs = builtins.filter (
          dependency:
          !(builtins.elem dependency [
            prev.cpptrace
            prev.libxcb
            prev.glib
            prev.polkit
          ])
        ) (old.buildInputs or [ ]);

        cmakeFlags =
          (old.cmakeFlags or [ ])
          ++ (with final.lib; [
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
        stripAllList = [
          "bin"
          "lib"
        ];
      });
}
