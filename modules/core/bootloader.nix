{ ... }:
{
  boot.loader = {
    systemd-boot.enable = false;
    efi.efiSysMountPoint = "/boot";
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
      useOSProber = true;
    };
  };
}