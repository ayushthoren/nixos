# Configuration for laptop with NVIDIA Dedicated Graphics (A2000 Mobile) & Intel Integrated Graphics
{ lib, pkgs, inputs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    # nixos-hardware flake handles things like tlp (power management) automatically
    inputs.nixos-hardware.nixosModules.dell-precision-5560
  ];

  # Network hostname (can be anything)
  networking.hostName = "precision";
  
  # Enable Hyprland performance mode (disables blur and shadow)
  home-manager.users.${username}.hyprland.performanceMode = true;
  
  environment.sessionVariables = {
    # Set environment variable to track flake config name
    NIXOS_FLAKE_HOST = "precision";
  };

  # Graphics configuration
  
  # boot.kernelParams = [
  #   "i915.enable_psr=0"
  #   "i915.enable_psr2_sel_fetch=0"
  # ];

  cachyosKernel.enable = true;
  ollama.enable = true;

  # Default profile uses integrated-only for battery
  nvidia.enable = false;

  # Power management
  systemd.sleep.settings.Sleep.HibernateDelaySec = "15min";

  services.tlp.settings = {
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;
    PLATFORM_PROFILE_ON_BAT = "low-power";
    PCIE_ASPM_ON_AC = "default";
    PCIE_ASPM_ON_BAT = "powersupersave";
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
    SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
    SOUND_POWER_SAVE_ON_BAT = 1;
    USB_AUTOSUSPEND = 1;
    WIFI_PWR_ON_BAT = "on";
  };

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime
    intel-vaapi-driver
    libva-vdpau-driver
    libvdpau-va-gl
  ];

  # Keep the dGPU driver stack unloaded in the default profile
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  boot.kernelParams = [
    "module_blacklist=nouveau,nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm"
  ];

  systemd.services.disable-nvidia-dgpu = {
    description = "Disable NVIDIA dGPU";
    wantedBy = [ "multi-user.target" ];
    after = [
      "sys-subsystem-pci-devices-0000:01:00.0.device"
      "sys-subsystem-pci-devices-0000:01:00.1.device"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      for dev in 0000:01:00.1 0000:01:00.0; do
        path=/sys/bus/pci/devices/$dev

        if [ -e "$path/driver/unbind" ]; then
          echo "$dev" > "$path/driver/unbind" || true
        fi

        if [ -e "$path/remove" ]; then
          echo 1 > "$path/remove" || true
        fi
      done
    '';
  };

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

      environment.variables = lib.mkForce {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
      };

      boot.blacklistedKernelModules = lib.mkForce [ "nouveau" ];
      boot.kernelParams = lib.mkForce [ "module_blacklist=nouveau" ];
      systemd.services.disable-nvidia-dgpu.enable = lib.mkForce false;
    };
  };

  # Fingerprint reader
  # services.fprintd.enable = true;
  # security.pam.services.sudo.fprintAuth = true;
  # security.pam.services.ly.fprintAuth = true;
}
