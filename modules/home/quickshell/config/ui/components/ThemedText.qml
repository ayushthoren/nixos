import QtQuick

import "../.."

Text {
    required property Theme theme
    textFormat: Text.PlainText
    color: theme.palette.foreground
    font.family: theme.fontFamily
    font.pixelSize: theme.fontPixelSize
}
