import QtQuick
import QtQuick.Layouts

import Quickshell.Hyprland

import ".."
import "components"

Rectangle {
    id: root
    required property Theme theme
    readonly property var colors: theme.palette

    implicitWidth: row.implicitWidth + root.theme.pillHorizontalPadding
    implicitHeight: root.theme.barHeight
    color: colors.surface

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                id: workspace
                // Keep ObjectModel data dynamic: typed workspace pointers lose
                // their properties in this Quickshell build.
                required property var modelData
                readonly property bool shown: workspace.modelData.active || workspace.modelData.focused || workspace.modelData.urgent || workspace.modelData.hasFullscreen || ((workspace.modelData.toplevels?.values.length ?? 0) > 0)

                implicitWidth: shown ? label.implicitWidth + root.theme.workspaceHorizontalPadding : 0
                implicitHeight: root.theme.barHeight
                visible: shown
                color: workspace.modelData.active ? root.colors.activeSurface : root.colors.surface

                ThemedText {
                    id: label
                    theme: root.theme
                    anchors.centerIn: parent
                    text: workspace.modelData.id
                    color: workspace.modelData.active ? root.colors.activeForeground : root.colors.foreground
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.visible
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspace.modelData.id}" })`)
                }
            }
        }
    }
}
