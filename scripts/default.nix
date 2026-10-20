{ pkgs, ... }:
{
  home.packages =
    map
      (
        name:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.nixos-rebuild
            pkgs.openssh
            pkgs.nix-output-monitor
          ];
          text = builtins.readFile ./rebuild.sh;
        }
      )
      [
        "rebuild"
        "rebuild-test"
        "rebuild-boot"
      ];
}
