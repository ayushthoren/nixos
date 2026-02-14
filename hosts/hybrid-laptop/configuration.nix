# Configuration for laptop with NVIDIA Dedicated Graphics (A2000 Mobile) & Intel Integrated Graphics
{ config, pkgs, inputs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    # nixos-hardware flake handles things like tlp (power management) automatically.
    inputs.nixos-hardware.nixosModules.dell-precision-5560
  ];

  # Network hostname (can be anything)
  networking.hostName = "precision";
  
  # Enable Hyprland performance mode (disables blur and shadow)
  home-manager.users.${username}.hyprland.performanceMode = true;
  
  environment.sessionVariables = {
    # Set environment variable to track flake config name
    NIXOS_FLAKE_HOST = "hybrid-laptop";
  };

  # Graphics configuration
  
  # boot.kernelParams = [
  #   "i915.enable_psr=0"
  #   "i915.enable_psr2_sel_fetch=0"
  # ];

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime
    intel-vaapi-driver
    libva-vdpau-driver
    libvdpau-va-gl
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    # package = config.boot.kernelPackages.nvidiaPackages.beta;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0"; 
    };
  };

  programs.xwayland.enable = true;
  environment.variables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  # Fingerprint reader
  # services.fprintd.enable = true;
  # security.pam.services.sudo.fprintAuth = true;
  # security.pam.services.ly.fprintAuth = true;
}