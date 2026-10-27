{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.gh ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };
}
