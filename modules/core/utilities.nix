{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # System utilities
    btop
    unzip
    cowsay
    nmap
    rclone
    geekbench
    zip
    sshpass
    ripgrep
    jq
    librsvg
    cava
    cmatrix
    asciiquarium
  ];
}
