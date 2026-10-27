{ pkgs, username, ... }:
{
  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "disk"
      "uudev"
      "audio"
      "video"
      "input"
      "kvm"
      "libvirtd"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
