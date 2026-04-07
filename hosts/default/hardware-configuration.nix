# Generate using `nixos-generate-config` and move the generated `hardware-configuration.nix` file here.
# Or, use the installation script!


# This is placeholder so `nix flake check` doesn't complain.
{ config, lib, pkgs, modulesPath, ... }: { imports = [ ]; boot.initrd.availableKernelModules = [ "sd_mod" "uhci_hcd" "nvme" ]; boot.initrd.kernelModules = [ ]; boot.kernelModules = [ "kvm-intel" ]; boot.extraModulePackages = [ ]; fileSystems."/" = { device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; fsType = "ext4"; }; swapDevices = [ { device = "/dev/disk/by-uuid/YYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"; } ]; networking.useDHCP = lib.mkDefault true; powerManagement.cpuFreqGovernor = lib.mkDefault "powersave"; }
