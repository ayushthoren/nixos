# Miscellaneous system configurations
{ pkgs, inputs, username, ... }:
{
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # Add user to trusted users for using additional binary caches
  nix.settings.trusted-users = [ "root" "@wheel" username ];

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
    efibootmgr
    lshw
    git
  ];

  system.stateVersion = "25.05";
}