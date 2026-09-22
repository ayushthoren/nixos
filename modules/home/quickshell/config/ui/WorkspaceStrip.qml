import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property QtObject theme
    required property var palette

    implicitWidth: row.implicitWidth + theme.pillHorizontalPadding
    implicitHeight: theme.barHeight
    color: palette.surface

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                readonly property bool shown: modelData.active
                    || modelData.focused
                    || modelData.urgent
                    || modelData.hasFullscreen
                    || ((modelData.toplevels?.values.length ?? 0) > 0)

                implicitWidth: shown ? label.implicitWidth + theme.workspaceHorizontalPadding : 0
                implicitHeight: theme.barHeight
                visible: shown
                color: modelData.active ? root.palette.activeSurface : root.palette.surface

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData.id
                    color: modelData.active ? root.palette.activeForeground : root.palette.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontPixelSize
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.visible
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${modelData.id}" })`)
                }
            }
        }
    }
}
