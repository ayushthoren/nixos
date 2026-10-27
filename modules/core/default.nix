{ ... }:
{
  imports = [
    ../../scripts
    ./bootloader.nix
    ./git.nix
    ./kernel.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./secrets.nix
    ./ssh.nix
    ./ollama.nix
    ./containers.nix
    ./development.nix
    ./utilities.nix
    ./memory.nix
    ./system.nix
    ./user.nix
  ];
}
