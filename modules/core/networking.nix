{ ... }:
{
  networking = {
    networkmanager = {
      enable = true;
    };
  };

  hardware.bluetooth.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };
}