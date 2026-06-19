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

    # Waybar from git
    (final: prev: {
      waybar = (prev.waybar.override {
        cavaSupport = false;
      }).overrideAttrs {
        src = final.fetchFromGitHub {
          owner = "Alexays";
          repo = "Waybar";
          rev = "05945748dccce28bf96d26d8f64a9e69a8dd49ba";
          hash = "sha256-51R3mIt8cLNvh/X5qe9vOqeJCj0U9KRyemVE5y+OhiU=";
        };
      };
    })

  ];
}
