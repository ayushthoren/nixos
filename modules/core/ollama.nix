{ config, lib, pkgs, inputs, ... }:

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
      package = lib.mkIf (config.nvidia.enable or false) pkgs.ollama-cuda;
      modelsDir = "/var/lib/ollama/models";
      loadModels = [ "gemma3:1b" ];
    };

    services.open-webui = {
      enable = false;
      environment = {
        # ENABLE_PERSISTENT_CONFIG = "False";
        WEBUI_AUTH = "False";
        TASK_MODEL = "gemma3:1b";
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_ENGINE = "duckduckgo";
      };
    };
  };
}
