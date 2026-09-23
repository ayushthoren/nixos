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
    enable = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "v3" "v4" "zen4" ]);
      default = null;
      description = "CachyOS kernel variants via nix-cachyos-kernel";
    };
  };

  config = lib.mkIf (cfg.enable != null) {
    nixpkgs.overlays = [
      inputs.nix-cachyos-kernel.overlays.default
    ];

    boot.kernelPackages = kernelPackages.${cfg.enable};
  };
}
