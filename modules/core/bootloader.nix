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
        efi.efiSysMountPoint = "/boot";
        grub = {
          enable = true;
          efiSupport = true;
          efiInstallAsRemovable = true;
          device = "nodev";
          useOSProber = true;
        };
      }
      (lib.mkIf cfg.enable (lib.mkForce {
        systemd-boot.enable = false;
        grub = {
          enable = true;
          efiSupport = false;
          efiInstallAsRemovable = false;
          device = cfg.device;
          useOSProber = false;
        };
      }))
    ];
  };
}
