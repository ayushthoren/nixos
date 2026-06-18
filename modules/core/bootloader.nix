{ config, lib, ... }:

let
  cfg = config.legacyBootloader;
in
{
  options.legacyBootloader = {
    enable = lib.mkEnableOption "legacy BIOS GRUB bootloader support";

    device = lib.mkOption {
      type = lib.types.str;
      default = "nodev";
      description = "Disk device where GRUB should be installed for legacy BIOS boot.";
    };
  };

  config = {
    boot.loader = lib.mkMerge [
      {
        systemd-boot.enable = false;
        grub = {
          enable = true;
          efiInstallAsRemovable = false;
        };
      }

      (lib.mkIf (!cfg.enable) {
        efi = {
          efiSysMountPoint = "/boot";
          canTouchEfiVariables = true;
        };
        grub = {
          efiSupport = true;
          device = "nodev";
          useOSProber = true;
        };
      })

      (lib.mkIf cfg.enable {
        efi.canTouchEfiVariables = false;
        grub = {
          efiSupport = false;
          device = cfg.device;
          useOSProber = false;
        };
      })
    ];
  };
}
