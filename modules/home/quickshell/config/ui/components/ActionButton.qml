import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    required property QtObject theme
    readonly property var colors: theme.palette
    property string trailingText: ""
    readonly property bool activeStyle: hovered || down || checked
    id: button
    implicitHeight: 30
    HoverHandler { cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    leftPadding: 10; rightPadding: 10
    font.family: theme.fontFamily
    font.pixelSize: theme.fontPixelSize
    background: Rectangle {
        color: button.activeStyle ? colors.activeSurface : colors.overlay
        opacity: button.enabled ? 1 : 0.4
    }
    contentItem: RowLayout {
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: button.text
            font: button.font
            color: button.activeStyle ? colors.activeForeground : colors.foreground
            horizontalAlignment: button.trailingText ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: button.enabled ? 1 : 0.4
        }
        Text {
            visible: button.trailingText !== ""
            text: button.trailingText
            font: button.font
            color: button.activeStyle ? colors.activeForeground : colors.mutedForeground
            opacity: button.enabled ? 1 : 0.4
        }
    }
}
