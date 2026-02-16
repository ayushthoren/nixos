{ ... }:
{
  networking = {
    networkmanager = {
      enable = true;
    };
  };

  hardware.bluetooth.enable = true;

  services.openssh = {
    enable = false;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };
}