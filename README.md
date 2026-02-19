# NixOS Flake

This repository contains my NixOS configuration files. This includes everything I need to recreate my system, including the OS-level config, the apps I like to have installed, and my rice dotfiles.

Multiple hosts are defined for each of my devices that I have used NixOS on. This allows me to have certain compatibility fixes / extra features for the devices that need it. (Nvidia drivers, different bootloaders, etc.)

If you are attempting to use this flake for your own device, I would recommend at least going through the installed apps and removing/adding stuff as you see fit. You would probably also have to create a new host that specifically suits all of the quirks of your machine.

I use [Hyprland](https://hypr.land/) as my window manager. If you use this flake and change the wallpaper using `waypaper`, a new color scheme for the system will be generated and applied accordingly! (`fastfetch` looks pretty cool too.)

This configuration uses `nixos-unstable` as the source for nixpkgs, so you can expect things to break occasionally when you choose to update. Usually fixing it is as simple as disabling a certain package with a build error for a bit. (You could also make your own patch or get an existing one that hasn't propagated into `nixos-unstable` yet and add it as an overlay if you really need the broken package).

# Usage

## Installation on a Fresh NixOS System

After installing NixOS using the graphical installer (or minimal ISO), follow these steps:

1. **Get git** (if not already available):
   ```bash
   nix-shell -p git
   ```

2. **Clone this repository** to `~/nixos`:
   ```bash
   git clone https://github.com/ayushthoren/nixos ~/nixos
   ```

3. **Run the installation script**:
   ```bash
   cd ~/nixos
   ./install.sh
   ```

The installation script will:
- Guide you through selecting a host configuration (choose "default" for a generic system)
- Automatically detect your username
- Generate a new hardware configuration (if using the default host)
- Build and install the system
- Reboot automatically upon completion

**Note:** The repository must be located at `~/nixos` for full compatibility with the command aliases and config symlink system.

## Manual Installation

If you prefer to build manually, use the following command (replace `your-host` with your desired host configuration):
```bash
sudo nixos-rebuild --flake ~/nixos#your-host
```

After the initial build, you can use the `rebuild` command and it will be equivalent to the above command (including whatever host you put in!).

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
- `F11` - Fullscreen

**Navigation**
- `Super + Arrow Keys` - Move focus between windows

**Workspaces**
- `Super + [1-9, 0]` - Switch to workspace 1-10
- `Super + Shift + [1-9, 0]` - Move active window to workspace 1-10
- `Super + Tab` - Switch to previous workspace
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
