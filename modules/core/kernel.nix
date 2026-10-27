{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.cachyosKernel;
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
      (import ../../overlays/optimized/kernel.nix { inherit inputs; })
    ];

    boot.kernelPackages = pkgs.optimizedKernelPackages.${cfg.variant};
  };
}
