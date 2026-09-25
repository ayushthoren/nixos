{ username, ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Add one plaintext Ed25519 public key per enrolled machine.
  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFa9OqZ1ztSYSR6PWJ2vcyqGYY/moIDnsOiIDRmnwzd thoren@x"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsXYhuRfDA0kVUVYqVxQGU3+wY4tiPOuEv1qxfaGWAd thoren@precision"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBslE4xq4/DnYULoOxWBGTPR4x4/DhLxiXLveyYTIHpX thoren@spectre"
  ];
}
