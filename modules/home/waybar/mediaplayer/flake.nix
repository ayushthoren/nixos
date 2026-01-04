{
  description = "Waybar mediaplayer (GI-wrapped)";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    pythonEnv = pkgs.python312.withPackages (ps: [ ps.pygobject3 ]);
  in {
    packages.${system}.mediaplayer = pkgs.stdenv.mkDerivation {
      pname = "waybar-mediaplayer";
      version = "1.0";
      src = ./.;

      nativeBuildInputs = [ pkgs.wrapGAppsHook ];
      buildInputs = [
        pythonEnv
        pkgs.playerctl
        pkgs.gobject-introspection
        pkgs.glib
      ];

      installPhase = ''
        mkdir -p $out/bin
        cat > $out/bin/waybar-mediaplayer <<'SH'
        #!${pkgs.bash}/bin/bash
        export GI_TYPELIB_PATH="${pkgs.playerctl}/lib/girepository-1.0''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
        export LD_LIBRARY_PATH="${pkgs.playerctl}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        exec ${pythonEnv}/bin/python ${placeholder "out"}/share/waybar-mediaplayer/mediaplayer.py
        SH
        chmod +x $out/bin/waybar-mediaplayer

        mkdir -p $out/share/waybar-mediaplayer
        cp mediaplayer.py $out/share/waybar-mediaplayer/
      '';
    };

    apps.${system}.mediaplayer = {
      type = "app";
      program = "${self.packages.${system}.mediaplayer}/bin/waybar-mediaplayer";
    };
  };
}
