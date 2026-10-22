{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.cachyosKernel;
  kernelConfig = import ./config.nix {
    inherit lib;
    variant = cfg.variant;
  };

  kernelPkgs = pkgs.extend (_: prev: {
    llvmPackages = prev.llvmPackages_23;
    linuxKernel = pkgs.linuxKernel;
  });

  kernelPackages = {
    v3 = kernelPkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3;
    v4 = kernelPkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v4;
    zen4 = kernelPkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
  };
in
{
  options.cachyosKernel = {
    enable = lib.mkEnableOption "CachyOS kernel";

    variant = lib.mkOption {
      type = lib.types.enum [
        "v3"
        "v4"
        "zen4"
      ];
      default = "v3";
      description = "CachyOS kernel variants via nix-cachyos-kernel";
    };
  };

  config = lib.mkIf cfg.enable {
    # Initrd storage and input drivers
    boot.initrd = {
      includeDefaultModules = false;
      availableKernelModules =
        lib.genAttrs [
          "ahci"
          "nvme"
          "sd_mod"
          "sr_mod"
          "usb_storage"
          "xhci_pci"
          "ehci_pci"
          "usbhid"
          "hid_generic"
          "hid_apple"
          "hid_logitech_dj"
          "hid_logitech_hidpp"
          "hid_microsoft"
          "hid_cherry"
          "hid_corsair"
          "atkbd"
          "i8042"
        ] (_: true)
        // {
          # ext4 handles ext2 (EXT4_USE_FOR_EXT2)
          ext2 = lib.mkForce false;
        };
      kernelModules = [ "dm_mod" ];
    };

    nixpkgs.overlays = [
      inputs.nix-cachyos-kernel.overlays.default
    ];

    boot.kernelPackages = kernelPackages.${cfg.variant}.extend (
      _: prev: {
        kernel = prev.kernel.override {
          # Explicit module selection
          autoModules = false;
          postPatch = ''
            sed -i -E 's/^(CONFIG_[A-Za-z0-9_]+)=m$/# \1 is not set/' arch/x86/configs/cachyos_defconfig
            # Whole-kernel ThinLTO worker count
            substituteInPlace scripts/Makefile.vmlinux_o \
              --replace-fail '$(LD) ''${KBUILD_LDFLAGS} -r -o $@' \
              '$(LD) ''${KBUILD_LDFLAGS} --threads=$(NIX_BUILD_CORES) --thinlto-jobs=$(NIX_BUILD_CORES) -r -o $@'
          '';
          structuredExtraConfig = lib.mapAttrs (_: lib.mkForce) kernelConfig;
        };
      }
    );
  };
}
