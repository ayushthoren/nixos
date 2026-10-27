# Miscellaneous system configurations
{ pkgs, ... }:
{
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    efibootmgr
    lshw
    wget
    cacert
  ];

  system.stateVersion = "25.05";
}
