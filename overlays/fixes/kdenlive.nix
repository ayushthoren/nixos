# Pin Kdenlive to avoid a cache miss
final: prev:
let
  kdenlivePkgs =
    import
      (builtins.fetchTree {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "f13ff45afd1bb73e640eaa08a7066dbed07e3238";
        narHash = "sha256-zDSUbpoeo/9ZmD2+wXnzxoo1+uhL8vxc0b8yuYMKYq0=";
      })
      {
        system = prev.stdenv.hostPlatform.system;
        config = {
          allowUnfree = true;
        };
      };
in
{
  kdePackages = prev.kdePackages.overrideScope (
    kdeFinal: kdePrev: {
      kdenlive = kdenlivePkgs.kdePackages.kdenlive;
    }
  );
}
