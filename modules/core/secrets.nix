{ config, inputs, lib, pkgs, username, hostname, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.secrets = lib.mkEnableOption "SOPS-managed secrets";

  config = lib.mkIf config.secrets {
    sops = {
      age.keyFile = "/etc/sops/age/keys.txt";

      defaultSopsFile = ../../secrets/${hostname}.yaml;

      secrets.tailscale_oauth_secret = { sopsFile = ../../secrets/shared.yaml; };
      secrets.ssh_private_key = {
        owner = username;
        mode = "0600";
      };
    };

    environment.systemPackages = with pkgs; [
      age
      sops
    ];

    programs.ssh.extraConfig = ''
      Host *
        IdentityFile ${config.sops.secrets.ssh_private_key.path}
    '';
  };
}

/*
Enroll a new host:
(Use `nix-shell -p age sops` to avoid rebuilding before the secrets are properly initialized.)

1. Generate Age key:
  sudo mkdir -p /etc/sops/age
  sudo age-keygen -o /etc/sops/age/keys.txt
  sudo chmod 600 /etc/sops/age/keys.txt
  sudo age-keygen -y /etc/sops/age/keys.txt

Add the printed age1... recipient to .sops.yaml and create a rule for
secrets/<hostname>.yaml using *master and *<hostname>.

2. Generate SSH key:
  ssh-keygen -t ed25519 -N "" -f /tmp/nixos_ssh_key

Add /tmp/nixos_ssh_key.pub to authorizedKeys in ssh.nix.

3. Create secrets file:
  sudo SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops secrets/<hostname>.yaml

Add:
  ssh_private_key: |
    <contents of /tmp/nixos_ssh_key>

Verify the saved file is encrypted, then:
  rm /tmp/nixos_ssh_key /tmp/nixos_ssh_key.pub

Useful:
  sudo age-keygen -y /etc/sops/age/keys.txt
  sudo SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops secrets/<filename>.yaml
  sudo SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops -d secrets/<filename>.yaml
  sudo SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops updatekeys secrets/<filename>.yaml
*/
