{ pkgs, config, ... }:
{
  home.packages = [ pkgs.tirith ];

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
      if [[ "$TERM" == "xterm-kitty" ]]; then
        typeset -A ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES=(
          alias fg=12
          arg0 fg=12
          autodirectory fg=12,underline
          builtin fg=12
          command fg=12
          function fg=12
          hashed-command fg=12
          precommand fg=12,bold
          reserved-word fg=14
          unknown-token fg=13,underline
          comment fg=8
        )
      else
        ZSH_HIGHLIGHT_HIGHLIGHTERS=()
      fi

      [[ ! -f ${config.home.homeDirectory}/nixos/modules/home/zsh/p10k.zsh ]] || source ${config.home.homeDirectory}/nixos/modules/home/zsh/p10k.zsh
      if [[ $- == *i* ]]; then
        if [[ "$TERM" == "xterm-kitty" ]]; then
          fastfetch
        fi
        eval "$(tirith init --shell zsh)"
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