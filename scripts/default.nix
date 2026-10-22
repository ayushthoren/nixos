{ pkgs, ... }:
let
  command = name: runtimeInputs: source: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ pkgs.openssh pkgs.coreutils pkgs.nix-output-monitor ] ++ runtimeInputs;
    text = builtins.readFile ./common.sh + "\n" + builtins.readFile source;
  };
in
{
  home.packages =
    map
      (
        name:
        command name [
          pkgs.nixos-rebuild
        ] ./rebuild.sh
      )
      [
        "rebuild"
        "rebuild-test"
        "rebuild-boot"
      ]
    ++ [
      (command "cache-kernels" [ pkgs.nix pkgs.cachix pkgs.jq pkgs.curl ] ./cache-kernels.sh)
    ];
}
