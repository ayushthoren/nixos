# Miscellaneous system configurations
{ pkgs, inputs, username, ... }:
{
  nix = {
    optimise.automatic = true;

    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" username ];
    };
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '' + builtins.readFile ./caches.conf;
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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  documentation.nixos.enable = false;

  # Register the flake in the system registry
  nix.registry.nixos.flake = inputs.self;

  services.flatpak.enable = true;

  nixpkgs.config.allowUnfree = true;

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    efibootmgr
    lshw
    wget
    cacert
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  system.stateVersion = "25.05";
}
