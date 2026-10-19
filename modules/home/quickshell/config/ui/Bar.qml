import Quickshell
import Quickshell.Io
import QtQuick
import "components"
import QtQuick.Layouts

import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Networking

import "../utils"

PanelWindow {
    readonly property QtObject uiTheme: theme
    id: bar
    required property var lockScreen
    required property QtObject theme

    anchors { top: true; left: true; right: true }
    implicitHeight: theme.barHeight
    color: palette.background

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    CommandPoller {
        id: batteryCapacity
        command: [ "sh", "-c", "[ -f /sys/class/power_supply/BAT0/capacity ] && cat /sys/class/power_supply/BAT0/capacity" ]
        interval: 5000
    }

    CommandPoller {
        id: batteryPower
        command: [ "sh", "-c", "[ -f /sys/class/power_supply/AC/online ] && cat /sys/class/power_supply/AC/online" ]
        interval: 5000
    }

    VolumeListener {
        id: volumeFallback
        enabled: !bar.audio
        sinkId: Pipewire.defaultAudioSink?.id ?? null
    }

    Process {
        id: identity
        command: [ "sh", "-c", "printf '%s@%s' \"$USER\" \"$(hostname)\"" ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: sessionIdentity = this.text.trim()
        }
    }

    property string sessionIdentity: ""
    property var palette: theme.palette
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property string volumeLabel: {
        if (audio) return `${Math.round(audio.volume * 100)}${audio.muted ? "M" : ""}`;
        const match = /^Volume:\s+([0-9]+(?:\.[0-9]+)?)(\s+\[MUTED\])?$/.exec(volumeFallback.value);
        return match ? `${Math.round(Number(match[1]) * 100)}${match[2] ? "M" : ""}` : "N/A";
    }
    readonly property var activeDevice: Networking.devices.values.find(device => device.connected) ?? null
    readonly property var activeNetwork: activeDevice?.network ?? activeDevice?.networks?.values.find(network => network.connected) ?? null
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property bool focusedWorkspaceEmpty: (focusedWorkspace?.toplevels?.values.length ?? 0) === 0
    readonly property string focusedTitle: (!focusedWorkspaceEmpty && Hyprland.activeToplevel?.title ? Hyprland.activeToplevel.title : (sessionIdentity || "~"))
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string playerLabel: { if (!player) {return "";} const title = player.trackTitle || ""; const artist = player.trackArtist || ""; return artist ? `${artist} - ${title}` : title; }
    readonly property bool batteryCharging: batteryPower.value === "1"
    readonly property real batteryPercent: { const fileValue = Number(batteryCapacity.value); return Number.isFinite(fileValue) ? fileValue : NaN; }
    readonly property bool hasBattery: Number.isFinite(batteryPercent)

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property int maxLabelWidth: 400

        implicitWidth: pillRow.implicitWidth + bar.theme.pillHorizontalPadding
        implicitHeight: bar.theme.barHeight
        color: bar.palette.surface

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: bar.theme.pillSpacing

            StyledText {
                theme: uiTheme
                text: pill.label
                color: bar.palette.foreground
                font.family: bar.theme.fontFamily
                font.pixelSize: bar.theme.fontPixelSize
                elide: Text.ElideRight
                Layout.maximumWidth: pill.maxLabelWidth
                visible: text !== ""
            }
        }
    }

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        WorkspaceStrip { theme: bar.theme; palette: bar.palette }
        Pill {
            id: mediaPill
            label: bar.playerLabel
            maxLabelWidth: 210
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (trayDropdown.visible) trayDropdown.closeAnimated();
                    if (powerMenu.visible) powerMenu.closeAnimated();
                    mediaDropdown.toggle();
                }
            }
        }
    }

    Pill {
        anchors.centerIn: parent
        label: bar.focusedTitle
        maxLabelWidth: 700
    }

    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Pill {
            id: trayPill
            label: `V(${SystemTray.items.values.length})`
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (mediaDropdown.visible) mediaDropdown.closeAnimated();
                    if (powerMenu.visible) powerMenu.closeAnimated();
                    trayDropdown.toggle();
                }
            }
        }
        Pill { label: bar.volumeLabel }
        Pill { label: bar.activeNetwork?.name ?? (bar.activeDevice ? bar.activeDevice.name : "Disconnected") }
        Pill { label: `${Math.round(bar.batteryPercent)}%${bar.batteryCharging ? "C" : ""}`; visible: bar.hasBattery }
        Pill { label: Qt.formatDateTime(clock.date, "ddd dd MMM") }
        Pill { label: Qt.formatDateTime(clock.date, "hh:mm:ss AP") }
        Pill { label: ""
            MouseArea {
                id: powerButton
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (mediaDropdown.visible) mediaDropdown.closeAnimated();
                    if (trayDropdown.visible) trayDropdown.closeAnimated();
                    powerMenu.toggle();
                }
            }
        }
    }

    Item {
        id: displayAnchor
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(430, bar.width)
        height: bar.height
    }

    DisplayPopup {
        id: displayPopup
        theme: bar.theme
        anchorItem: displayAnchor
    }

    IpcHandler {
        target: "display"
        function toggle(): void { displayPopup.toggle(); }
    }

    MediaPopup {
        id: mediaDropdown
        theme: bar.theme
        colors: bar.palette
        anchorItem: mediaPill
        player: bar.player
    }

    TrayPopup {
        id: trayDropdown
        theme: bar.theme
        colors: bar.palette
        anchorItem: trayPill
    }

    PowerPopup {
        id: powerMenu
        theme: bar.theme
        colors: bar.palette
        anchorItem: powerButton
        onLockRequested: bar.lockScreen.lock()
    }
}
