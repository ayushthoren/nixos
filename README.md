# NixOS Flake

This repository contains my NixOS configuration files. This includes everything I need to recreate my system, including the OS-level config, the apps I like to have installed, and my rice dotfiles.

Multiple hosts are defined for each of my devices that I have used NixOS on. This allows me to have certain compatibility fixes / extra features for the devices that need it. (Nvidia drivers, different bootloaders, etc.)

If you are attempting to use this flake for your own device, I would recommend at least going through the installed apps and removing/adding stuff as you see fit. You would probably also want/have to create a new host that specifically suits all of the quirks of your machine.

I use [Hyprland](https://hypr.land/) as my window manager. If you use this flake and change the wallpaper using `waypaper`, a new color scheme for the system will be generated and applied accordingly! (`fastfetch` looks pretty cool too.)

# Usage

When you `git clone` this repo, do so in your home directory, such that your config directory becomes `~/nixos` rather than `/etc/nixos`. This will allow you have full write permissions so you can easily edit the files without needing to authenticate for every little thing. It also ensures support for the command aliases used for building/updating/cleaning the system, as well as the config symlink system.

When building the system for the first time, `cd` into the repo directory and use the following command, replacing `your-host` with the name of the host configuration you wish to use (like `desktop` or `hybrid-laptop`).
```
sudo nixos-rebuild switch .#your-host
```

After the initial build, you can use the `rebuild` command and it will be equivalent to the above command (including whatever host you put in!). (`rebuild-test` and `rebuild-boot` are also provided to take care of the other rebuilding functionalities).

This configuration uses `nixos-unstable` as the source for nixpkgs, so you can expect things to break occasionally when you choose to update. Usually fixing it is as simple as disabling a certain package with a build error for a bit. (You could also make your own patch or get an existing one that hasn't propagated into `nixos-unstable` yet and add it as an overlay if you really need the broken package).

# Aliases
Rebuild the system and apply changes immediately:<br/>
`rebuild` = `sudo nixos-rebuild switch --flake ~/nixos#your-host`

Rebuild the system and apply changes without creating a new boot entry:<br/>
`rebuild-test` = `sudo nixos-rebuild test --flake ~/nixos#your-host`

Rebuild the system but don't apply changes until the next boot:<br/>
`rebuild-boot` = `sudo nixos-rebuild boot --flake ~/nixos#your-host`

Rollback the system to a previous generation immediately:<br/>
`rollback` = `sudo nixos-rebuild --rollback switch --flake ~/nixos#your-host`

Update the system (flake inputs):<br/>
`update` = `nix flake update --flake ~/nixos`

Garbage collect *all* previous configurations (make sure the current config is stable before using this, in case you need to rollback!):<br/>
`clean` = `nh clean all -k 1`

# Binds

**Window Management**
- `Super + Q` - Open terminal (kitty)
- `Super + C` - Kill active window
- `Super + M` - Exit Hyprland
- `Super + E` - Open file manager (thunar)
- `Super + V` - Toggle floating mode
- `Super + R` - Open application launcher (rofi)
- `Super + P` - Pseudotile (dwindle)
- `Super + J` - Toggle split (dwindle)
- `Super + Tab` - Switch to previous workspace
- `F11` - Fullscreen

**Navigation**
- `Super + Arrow Keys` - Move focus between windows

**Workspaces**
- `Super + [1-9, 0]` - Switch to workspace 1-10
- `Super + Shift + [1-9, 0]` - Move active window to workspace 1-10
- `Super + Mouse Scroll Up/Down` - Switch workspaces on current monitor

**Zoom**
- `Super + Shift + Mouse Scroll Up` - Zoom out
- `Super + Shift + Mouse Scroll Down` - Zoom in

**Mouse Actions**
- `Super + Left Mouse Button` - Move window
- `Super + Right Mouse Button` - Resize window
- `Super + Alt + Left Mouse Button` - Resize window (laptop)

**Utilities**
- `Super + Shift + S` - Take region screenshot (hyprshot)
- `Super + Shift + V` - Open clipboard history (cliphist + rofi)
- `Super + \` - Open calculator (rofi calc)
