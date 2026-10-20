# Configuration for laptop with NVIDIA Dedicated Graphics (A2000 Mobile) & Intel Integrated Graphics
{ lib, pkgs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # Network hostname (can be anything)
  networking.hostName = "precision";
  
  # Enable Hyprland performance mode (disables blur and shadow)
  home-manager.users.${username}.hyprland.performanceMode = true;
  
  environment.sessionVariables = {
    # Set environment variable to track flake config name
    NIXOS_FLAKE_HOST = "precision";
  };

  cachyosKernel = {
    enable = true;
    variant = "v4";
  };
  secrets.enable = true;
  ollama.enable = true;

  # Default profile uses integrated-only for battery
  nvidia.enable = false;

  # Power management
  systemd.sleep.settings.Sleep.HibernateDelaySec = "15min";

  services.tlp.enable = lib.mkForce false;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        energy_performance_preference = "balance_power";
        # scaling_max_freq = 2500000; # 2.5 GHz ceiling
        turbo = "never";
      };
      charger = {
        governor = "powersave";
        energy_performance_preference = "performance";
        turbo = "auto";
      };
    };
  };

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = [ pkgs.driversi686Linux.intel-media-driver ];
  };

  # Load Intel graphics early for the integrated display
  boot.initrd.kernelModules = [ "i915" ];

  # Keep the dGPU driver stack unloaded in the default profile
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  boot.kernelParams = [
    "i915.enable_guc=3"
    # "i915.enable_psr=0"
    # "i915.enable_psr2_sel_fetch=0"
    "module_blacklist=nouveau,nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm"
  ];

  # Allow the A2000 to suspend into D3cold
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:01:00.0", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:01.0", ATTR{power/control}="auto"
  '';

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  programs.xwayland.enable = lib.mkForce true;

  specialisation = {
    nvidia.configuration = {
      system.nixos.tags = [ "nvidia" ];

      nvidia.enable = lib.mkForce true;

      services.xserver.videoDrivers = lib.mkForce [
        "modesetting"
        "nvidia"
      ];

      hardware.nvidia = {
        powerManagement.enable = lib.mkForce true;
        powerManagement.finegrained = lib.mkForce true;
        # package = config.boot.kernelPackages.nvidiaPackages.beta;

        prime = {
          offload = {
            enable = lib.mkForce true;
            enableOffloadCmd = lib.mkForce true;
          };
          # sync.enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };

      environment.sessionVariables = {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
      };

      boot.blacklistedKernelModules = lib.mkForce [ "nouveau" ];
      boot.kernelParams = lib.mkForce [ "module_blacklist=nouveau" ];
    };
  };

  # Fingerprint reader
  # services.fprintd.enable = true;
  # security.pam.services.sudo.fprintAuth = true;
  # security.pam.services.ly.fprintAuth = true;
}
