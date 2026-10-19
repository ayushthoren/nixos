import QtQuick
import QtQuick.Controls

TextField {
    required property QtObject theme
    readonly property var colors: theme.palette
    implicitHeight: 34
    font.family: theme.fontFamily
    font.pixelSize: theme.fontPixelSize
    color: colors.foreground
    placeholderText: "Auto"
    placeholderTextColor: colors.mutedForeground
    selectionColor: colors.activeSurface
    selectedTextColor: colors.activeForeground
    selectByMouse: true
    padding: 8
    background: Rectangle {
        color: colors.overlay
        border.width: 1
        border.color: parent.activeFocus ? colors.foreground : theme.palette.inputBorder
    }
}
