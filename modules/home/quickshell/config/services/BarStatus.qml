import QtQuick

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland

import "../utils"

Scope {
    id: root
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property date clockDate: clock.date

    FilePoller {
        id: batteryCapacity
        path: "/sys/class/power_supply/BAT0/capacity"
        interval: 5000
    }

    FilePoller {
        id: batteryPower
        path: "/sys/class/power_supply/AC/online"
        interval: 5000
    }

    VolumeListener {
        id: volumeFallback
        enabled: !root.audio
        sinkId: Pipewire.defaultAudioSink?.id ?? null
    }

    Process {
        id: identity
        command: ["sh", "-c", "printf '%s@%s' \"$USER\" \"$(hostname)\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.sessionIdentity = this.text.trim()
        }
    }

    property string sessionIdentity: ""
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property string volumeLabel: {
        if (audio)
            return `${Math.round(audio.volume * 100)}${audio.muted ? "M" : ""}`;
        const match = /^Volume:\s+([0-9]+(?:\.[0-9]+)?)(\s+\[MUTED\])?$/.exec(volumeFallback.value);
        return match ? `${Math.round(Number(match[1]) * 100)}${match[2] ? "M" : ""}` : "N/A";
    }
    readonly property var activeDevice: Networking.devices.values.find(device => device.connected) ?? null
    readonly property var activeNetwork: activeDevice?.network ?? activeDevice?.networks?.values.find(network => network.connected) ?? null
    readonly property var focusedWorkspace: Hyprland.workspaces.values.find(workspace => workspace.focused) ?? null
    readonly property bool focusedWorkspaceEmpty: (focusedWorkspace?.toplevels?.values.length ?? 0) === 0
    readonly property string focusedTitle: (!focusedWorkspaceEmpty && ToplevelManager.activeToplevel?.title ? ToplevelManager.activeToplevel.title : (sessionIdentity || "~"))
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string playerLabel: {
        if (!player)
            return "";
        const title = player.trackTitle || "";
        const artist = player.trackArtist || "";
        return artist ? `${artist} - ${title}` : title;
    }
    readonly property bool batteryCharging: batteryPower.value === "1"
    readonly property real batteryPercent: {
        const value = batteryCapacity.value.trim();
        if (!value)
            return NaN;
        const percent = Number(value);
        return Number.isFinite(percent) && percent >= 0 && percent <= 100 ? percent : NaN;
    }
    readonly property bool hasBattery: Number.isFinite(batteryPercent)

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
