{ config, lib, ... }:
{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.resumeDevice = lib.mkIf (config.swapDevices != [ ]) (
    lib.mkDefault (builtins.head config.swapDevices).device
  );

  boot.kernelParams = [
    "hibernate.compressor=lz4"
    "hibernate_compression_threads=8"
  ];

  boot.initrd.kernelModules = [
    "lz4"
    "lz4_compress"
  ];
}
