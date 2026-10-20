{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.cachyosKernel;
  kernelPackages = {
    v3 = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3;
    v4 = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v4;
    zen4 = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
  };
in
{
  options.cachyosKernel = {
    enable = lib.mkEnableOption "CachyOS kernel";

    variant = lib.mkOption {
      type = lib.types.enum [ "v3" "v4" "zen4" ];
      default = "v3";
      description = "CachyOS kernel variants via nix-cachyos-kernel";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.nix-cachyos-kernel.overlays.pinned
    ];

    boot.kernelPackages = kernelPackages.${cfg.variant};
  };
}
