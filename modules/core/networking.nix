{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  services.resolved.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings.publish = {
      disable-publishing = false;
      publish-addresses = true;
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

  systemd.services.NetworkManager-wait-online.enable = false;
}
