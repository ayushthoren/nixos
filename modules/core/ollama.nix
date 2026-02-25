{ config, lib, pkgs, ... }:

let
  cfg = config.ollama;
in
{
  options.ollama = {
    enable = lib.mkEnableOption "Ollama and other local LLM tools";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      models = "/var/lib/ollama/models";
      loadModels = [ "gemma3:1b" ];
    };

    services.open-webui = {
      enable = true;
      environment = {
        # ENABLE_PERSISTENT_CONFIG = "False";
        WEBUI_AUTH = "False";
        TASK_MODEL = "gemma3:1b";
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_ENGINE = "duckduckgo";
      };
    };
    
    environment.systemPackages = with pkgs; [
      claude-code
    ];
    
    environment.sessionVariables = {
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
  };
}
