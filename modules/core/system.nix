# Miscellaneous system configurations
{ pkgs, inputs, username, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" username ];
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  security.polkit.enable = true;

  services.libinput.enable = true;

  # Disable high-resolution scrolling for all devices
  environment.etc."libinput/local-overrides.quirks" = {
    text = ''
      [disablehighresolutionscrollingforreal]
      MatchName=*
      AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
    '';
  };
  
  programs = {
    zsh.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Register the flake in the system registry
  nix.registry.nixos.flake = inputs.self;

  services.flatpak.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    efibootmgr
    lshw
    git
    wget
  ];

  system.stateVersion = "25.05";
}