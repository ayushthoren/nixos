import QtQuick

import "../.."

Rectangle {
    id: root
    required property Theme theme
    property string label: ""
    property int maxLabelWidth: 400
    signal clicked
    property bool interactive: false

    implicitWidth: labelText.implicitWidth > 0 ? Math.min(labelText.implicitWidth, maxLabelWidth) + theme.pillHorizontalPadding : theme.pillHorizontalPadding
    implicitHeight: theme.barHeight
    color: theme.palette.surface

    ThemedText {
        id: labelText
        theme: root.theme
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.maxLabelWidth)
        text: root.label
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
