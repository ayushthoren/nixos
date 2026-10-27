import QtQuick
import QtQuick.Layouts

import Quickshell

import "components"

AnimatedPopup {
    id: popup
    signal lockRequested
    property int selectedAction: 0

    readonly property var actions: [
        {
            label: "Lock",
            command: null
        },
        {
            label: "Hibernate",
            command: ["systemctl", "hibernate"]
        },
        {
            label: "Logout",
            command: ["sh", "-c", "exec loginctl terminate-user \"$USER\""]
        },
        {
            label: "Shutdown",
            command: ["systemctl", "poweroff"]
        },
        {
            label: "Suspend",
            command: ["systemctl", "suspend-then-hibernate"]
        },
        {
            label: "Reboot",
            command: ["systemctl", "reboot"]
        }
    ]

    implicitWidth: 160
    implicitHeight: 216

    onAboutToOpen: selectedAction = 0
    focusItem: keyHandler
    function run(index) {
        closeAnimated();
        if (index === 0)
            lockRequested();
        else
            Quickshell.execDetached(actions[index].command);
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: popup.closeFade()
        Keys.onPressed: event => {
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
                popup.selectedAction = event.key - Qt.Key_1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                popup.selectedAction = (popup.selectedAction + popup.actions.length - 1) % popup.actions.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                popup.selectedAction = (popup.selectedAction + 1) % popup.actions.length;
                event.accepted = true;
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && popup.selectedAction >= 0) {
                popup.run(popup.selectedAction);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: popup.actions
                Rectangle {
                    id: actionButton
                    required property var modelData
                    required property int index
                    readonly property bool highlighted: actionHover.hovered || popup.selectedAction === index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: highlighted ? popup.colors.activeSurface : popup.colors.overlay

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        ThemedText {
                            theme: popup.theme
                            Layout.fillWidth: true
                            text: actionButton.modelData.label
                            color: actionButton.highlighted ? popup.colors.activeForeground : popup.colors.foreground
                        }
                        ThemedText {
                            theme: popup.theme
                            text: String(actionButton.index + 1)
                            color: actionButton.highlighted ? popup.colors.activeForeground : popup.colors.mutedForeground
                            font.pixelSize: popup.theme.fontPixelSize - 1
                        }
                    }
                    HoverHandler {
                        id: actionHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.run(actionButton.index)
                    }
                }
            }
        }
    }
}
