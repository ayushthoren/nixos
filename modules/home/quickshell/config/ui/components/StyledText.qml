import QtQuick

Text {
    required property QtObject theme
    color: theme.palette.foreground
    font.family: theme.fontFamily
    font.pixelSize: theme.fontPixelSize
    textFormat: Text.PlainText
}
