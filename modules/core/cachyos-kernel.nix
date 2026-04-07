{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.cachyosKernel;
in
{
  options.cachyosKernel = {
    enable = lib.mkEnableOption "CachyOS kernel via nix-cachyos-kernel";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.nix-cachyos-kernel.overlays.default
    ];

    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
  };
}
