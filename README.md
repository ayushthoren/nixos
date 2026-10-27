<div align="center">

# Thoren's NixOS Configuration

[![Flake](https://github.com/ayushthoren/nixos/actions/workflows/flake-check.yaml/badge.svg)](https://github.com/ayushthoren/nixos/actions/workflows/flake-check.yaml)&nbsp;&nbsp;&nbsp;
[![Build](https://github.com/ayushthoren/nixos/actions/workflows/nix-build.yaml/badge.svg)](https://github.com/ayushthoren/nixos/actions/workflows/nix-build.yaml)&nbsp;&nbsp;&nbsp;
[![Cache](https://github.com/ayushthoren/nixos/actions/workflows/cachix.yaml/badge.svg)](https://github.com/ayushthoren/nixos/actions/workflows/cachix.yaml)
</div>

My [NixOS](https://nixos.org) configuration, utilizing [flakes](https://wiki.nixos.org/wiki/Flakes) and [home-manager](https://github.com/nix-community/home-manager).

### Notable Features:
- Personal binary cache ([thoren.cachix.org](https://thoren.cachix.org))
- Trimmed [CachyOS](https://github.com/xddxdd/nix-cachyos-kernel) kernel builds optimized for my different hosts' platforms
- Some custom [quickshell](https://quickshell.org) for my desktop environment
- Automatically generated theming from wallpapers
- [Tailscale](https://tailscale.com) network connecting all of my devices together
- Support for offloading heavy build tasks to any device
- Encrypted secrets via [sops-nix](https://github.com/mic92/sops-nix)

<sub>*A [thoren.co](https://thoren.co) innovation!*</sub>