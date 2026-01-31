{ pkgs, config, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    # enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos#\${NIXOS_FLAKE_HOST}";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixos#\${NIXOS_FLAKE_HOST}";
      rebuild-boot = "sudo nixos-rebuild boot --flake ~/nixos#\${NIXOS_FLAKE_HOST}";
      rollback = "sudo nixos-rebuild --rollback switch --flake ~/nixos#\${NIXOS_FLAKE_HOST}";
      update = "nix flake update --flake ~/nixos";
      clean = "nh clean all -k 1";
    };

    initContent = ''
      [[ ! -f ${./p10k.zsh} ]] || source ${./p10k.zsh}
      if [[ $- == *i* ]]; then
        fastfetch
      fi
    '';
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };
}