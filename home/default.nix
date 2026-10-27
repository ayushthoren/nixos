{ inputs, username, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.${username} = {
      imports = [
        ./session.nix
        ./polkit.nix
        ./xdg.nix
        ./theming.nix
        ./kitty
        ./hyprland
        ./waypaper
        ./fastfetch
        ./rofi
        ./wallust
        ./quickshell
        ./zsh
        ./firefox
      ];
    };
  };
}
