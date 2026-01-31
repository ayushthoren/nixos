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

  ];
}
