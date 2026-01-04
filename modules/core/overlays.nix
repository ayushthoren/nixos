{ inputs, ... }:

{
  nixpkgs.overlays = [    

    # https://github.com/anufrievroman/waypaper/pull/220
    (final: prev: {
      waypaper = prev.waypaper.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [
          ../home/waypaper/fix-readonly-config.patch
        ];
      });
    })

    # https://github.com/NixOS/nixpkgs/pull/476514
    (final: prev: {
      vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
        preBuild = prev.lib.optionalString prev.stdenv.hostPlatform.isLinux ''
          cp -r ${prev.electron}/libexec/electron electron-dist
          chmod -R u+w electron-dist
        '';
        
        buildPhase = ''
          runHook preBuild
          
          pnpm build --standalone
          pnpm exec electron-builder \
            --dir \
            -c.asarUnpack="**/*.node" \
            -c.electronDist=electron-dist \
            -c.electronVersion=${prev.electron.version}
          
          runHook postBuild
        '';
      });
    })

  ];
}
