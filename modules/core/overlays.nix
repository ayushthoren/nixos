{ inputs, ... }:

{
  nixpkgs.overlays = [    

    # Rofi from git
    (final: prev: {
      rofi = prev.rofi.override {
        rofi-unwrapped = prev.rofi-unwrapped.overrideAttrs (oldAttrs: {
          src = final.fetchFromGitHub {
            owner = "davatorium";
            repo = "rofi";
            rev = "89c768c1f98e49a762cb36bc40d941fd42e1c660";
            fetchSubmodules = true;
            sha256 = "sha256-ckTsPjzWx2WzrV+rZfNB00UNStlaZ9NLJonjYRSR4/k=";
          };
          version = "git";
          doInstallCheck = false;
        });
      };
    })

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
