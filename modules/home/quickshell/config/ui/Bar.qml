import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.SystemTray

import ".."
import "../services"
import "components"

PanelWindow {
    id: bar
    required property var lockScreen
    required property Theme theme

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: bar.theme.barHeight
    color: palette.background

    BarStatus {
        id: status
    }
    readonly property var palette: bar.theme.palette

    function togglePopup(popup) {
        for (const other of [mediaDropdown, trayDropdown, powerMenu]) {
            if (other !== popup && other.visible)
                other.closeAnimated();
        }
        popup.toggle();
    }

    RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        WorkspaceStrip {
            theme: bar.theme
        }
        BarPill {
            id: mediaPill
            theme: bar.theme
            label: status.playerLabel
            maxLabelWidth: 210
            interactive: true
            onClicked: bar.togglePopup(mediaDropdown)
        }
    }

    BarPill {
        theme: bar.theme
        anchors.centerIn: parent
        label: status.focusedTitle
        maxLabelWidth: 700
    }

    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        BarPill {
            id: trayPill
            theme: bar.theme
            label: `V(${SystemTray.items.values.length})`
            interactive: true
            onClicked: bar.togglePopup(trayDropdown)
        }
        BarPill {
            theme: bar.theme
            label: status.volumeLabel
        }
        BarPill {
            theme: bar.theme
            label: status.activeNetwork?.name ?? (status.activeDevice ? status.activeDevice.name : "Disconnected")
        }
        BarPill {
            theme: bar.theme
            label: `${Math.round(status.batteryPercent)}%${status.batteryCharging ? "C" : ""}`
            visible: status.hasBattery
        }
        BarPill {
            theme: bar.theme
            label: Qt.formatDateTime(status.clockDate, "ddd dd MMM")
        }
        BarPill {
            theme: bar.theme
            label: Qt.formatDateTime(status.clockDate, "hh:mm:ss AP")
        }
        BarPill {
            id: powerButton
            theme: bar.theme
            label: ""
            interactive: true
            onClicked: bar.togglePopup(powerMenu)
        }
    }

    MediaPopup {
        id: mediaDropdown
        theme: bar.theme
        colors: bar.palette
        anchorItem: mediaPill
        player: status.player
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
