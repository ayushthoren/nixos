{ config, lib, pkgs, ... }:

let
  cfg = config.nvidia;
in
{
  options.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.cudaSupport = true;

    hardware.nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
    };

    services.ollama.package = pkgs.ollama-cuda;
  };
}
