{ osConfig, lib, pkgs, ... }:
{
  home.packages = [ pkgs.gh ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = lib.mkIf osConfig.secrets.enable {
      core.sshCommand = "${pkgs.openssh}/bin/ssh -i ${osConfig.sops.secrets.git_ssh_private_key.path}";
      gpg.format = "ssh";
      user.signingkey = osConfig.sops.secrets.git_ssh_private_key.path;
      commit.gpgsign = true;
      tag.gpgsign = true;
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };
}
