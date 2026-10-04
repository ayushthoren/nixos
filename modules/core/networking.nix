{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  services.resolved.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}