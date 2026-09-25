{ ... }:
{
  networking = {
    networkmanager = {
      enable = true;
    };
  };

  hardware.bluetooth.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
}
