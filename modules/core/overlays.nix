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
            rev = "f1ee9b8e4a612ce7d13eeb57f8fe81b985900071";
            fetchSubmodules = true;
            sha256 = "sha256-Vqiqyq1KTr0DfSFr7FD7rG9wnWqrkZTobjLfR/aOkcQ=";
          };
          version = "git";
          doInstallCheck = false;
        });
      };
    })

    # Frei0r CUDA support
    (final: prev: {
      frei0r = prev.frei0r.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [])
          ++ [ final.cudaPackages.cuda_nvcc ];
      });
    })

  ];
}
