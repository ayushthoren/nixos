{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Games
    prismlauncher
  ];

  services.flatpak.packages = [
    {
      appId = "org.vinegarhq.Sober";
      origin = "flathub";
    }
    {
      appId = "com.lunarclient.LunarClient";
      origin = "flathub";
    }
  ];
}
