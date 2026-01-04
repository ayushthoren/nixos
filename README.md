# NixOS Flake

This repository contains my NixOS configuration files. This includes everything I need to recreate my system, including the OS-level config, the apps I like to have installed, and my rice dotfiles.

Multiple hosts are defined for each of my devices that I have used NixOS on. This allows me to have certain compatibility fixes / extra features for the devices that need it. (Nvidia drivers, different bootloaders, etc.)

If you are attempting to use this flake for your own device, I would recommend at least going through the installed apps and removing/adding stuff as you see fit. You would probably also want/have to create a new host that specifically suits all of the quirks of your machine.

I use [Hyprland](https://hypr.land/) as my window manager. If you use this flake and change the wallpaper using `waypaper`, a new color scheme for the system will be generated and applied accordingly! (`fastfetch` looks pretty cool too.)

# Usage
When you `git clone` this repo, do so in your home directory, such that your config directory becomes  `~/nixos` rather than `/etc/nixos`. This will allow you have full write permissions so you can easily edit the files without needing to authenticate for every little thing, and it also ensures support for the command aliases used for building/updating/cleaning the system.

When building the system for the first time, `cd` into the repo directory and use the following command, replacing `your-host` with the name of the host configuration you wish to use (like `desktop` or `hybrid-laptop`).
```
sudo nixos-rebuild switch .#your-host
```

After the initial build, you can use the `rebuild` command and it will be equivalent to the above command (including whatever host you put in!). (`rebuild-test` and `rebuild-boot` are also provided to take care of the other rebuilding functionalities).

This configuration uses `nixos-unstable` as the source for nixpkgs, so you can expect things to break occasionally when you choose to update. Usually fixing it is as simple as disabling a certain package with a build error for a bit. (You could also make your own patch or get an existing one that hasn't propagated into `nixos-unstable` yet and add it as an overlay if you really need the broken package).
