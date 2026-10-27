# Rofi from git
final: prev: {
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
}
