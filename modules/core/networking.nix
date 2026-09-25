{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

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

  systemd.services.tailscale-autoconnect = {
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    requires = [ "tailscaled.service" ];

    serviceConfig.Type = "oneshot";

    script = ''
      ${pkgs.tailscale}/bin/tailscale up \
        --auth-key="$(cat ${config.sops.secrets.tailscale_oauth_secret.path})?ephemeral=false&preauthorized=true" \
        --advertise-tags=tag:nixos
    '';
  };
}