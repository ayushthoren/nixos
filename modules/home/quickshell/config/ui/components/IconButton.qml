import QtQuick

StyledText {
    id: button
    signal clicked()
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    opacity: enabled ? (interaction.containsMouse ? 0.8 : 1) : 0.4
    MouseArea {
        id: interaction
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
