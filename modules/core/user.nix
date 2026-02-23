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

  # Ollama
  services.ollama.enable = true;
  services.open-webui.enable = true;

  # File manager
  programs.thunar.enable = true;
  programs.xfconf.enable = true;
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images   

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };

    users.${username} = { config, pkgs, lib, ... }: {
      imports = [ ./../home ];

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
        vlc
        kdePackages.okular
        adwaita-icon-theme
        cowsay
        mesa-demos
        qdirstat
        nmap
        rclone
        winboat
        podman-compose

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
        qbittorrent
        protonvpn-gui
        google-chrome
        obsidian
        
        # Games
        prismlauncher
      ];

      programs.firefox.enable = true; 

      # XDG default applications
      xdg = {
        enable = true;
        mimeApps.enable = true;
        mimeApps.defaultApplications = {
          "text/plain" = [ "code.desktop" ];
          "image/jpeg" = [ "org.kde.gwenview.desktop" ];
          "image/png" = [ "org.kde.gwenview.desktop" ];
          "video/mp4" = [ "vlc.desktop" ];
          "video/x-matroska" = [ "vlc.desktop" ];
          "application/pdf" = [ "okular.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
        };
      };

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