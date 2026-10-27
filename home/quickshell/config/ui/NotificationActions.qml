import QtQuick

import Quickshell.Services.Notifications
import Quickshell.Widgets

import ".."
import "components"

Flow {
    id: root
    required property Theme theme
    required property Notification notification
    required property var colors
    signal invoked(var action)
    visible: root.notification.actions.length > 0
    spacing: 6

    Repeater {
        model: root.notification.actions

        Rectangle {
            id: action
            required property NotificationAction modelData

            implicitWidth: actionRow.implicitWidth + 12
            implicitHeight: 26
            color: root.colors.overlay

            Row {
                id: actionRow
                anchors.centerIn: parent
                spacing: 6

                IconImage {
                    implicitSize: 14
                    visible: root.notification.hasActionIcons
                    source: root.notification.hasActionIcons ? action.modelData.identifier : ""
                }

                ThemedText {
                    theme: root.theme
                    text: action.modelData.text
                    font.pixelSize: root.theme.fontPixelSize - 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.invoked(action.modelData)
            }
        }
    }
}
