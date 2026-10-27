{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Applications
    vscode-fhs
    spotify
    vesktop
    slack
    qbittorrent
    proton-vpn
    google-chrome
    obsidian
    gimp
    blender
    obs-studio
    kdePackages.kdenlive
    zoom-us

    kdePackages.ark
    kdePackages.gwenview
    kdePackages.okular
    vlc
    qdirstat
    gparted
    winboat
  ];
}
