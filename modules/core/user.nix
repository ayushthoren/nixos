{ pkgs, username, inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  services.flatpak.packages = [
    { appId = "org.vinegarhq.Sober"; origin = "flathub"; }
  ];

  programs.steam = { enable = true; };

  # File manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
    ];
  };
  programs.xfconf.enable = true;
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images   

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };

    users.${username} = { config, pkgs, lib, ... }: {
      imports = [
        ./../home
        ./xdg-defaults.nix
      ];

      home.stateVersion = "25.05";

      home.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_ENABLE_HIGHDPI_SCALING = "1";
        NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };

      home.packages = with pkgs; [
        # System utilities
        btop
        unzip
        nh
        librsvg
        kdePackages.gwenview
        kdePackages.ark
        vlc
        kdePackages.okular
        adwaita-icon-theme
        cowsay
        mesa-demos
        qdirstat
        gparted
        nmap
        rclone
        winboat
        podman-compose
        geekbench
        qemu
        zip

        # Wayland/Desktop utilities
        swaynotificationcenter
        libnotify

        # Development tools
        vscode-fhs
        nodejs
        python3
        jdk

        # Applications
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

        # Games
        prismlauncher
      ];

      systemd.user.services.polkit-gnome-authentication-agent-1 = {
        Unit = {
          Description = "polkit-gnome-authentication-agent-1";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
