import Quickshell
import QtQuick
import QtQuick.Layouts
import "components"

PopupFrame {
    readonly property QtObject uiTheme: theme
    id: popup
    focusTarget: keyHandler
    signal lockRequested()
    property int selectedAction: 0

    readonly property var actions: [
        { label: "Lock", command: null },
        { label: "Hibernate", command: [ "systemctl", "hibernate" ] },
        { label: "Logout", command: [ "sh", "-c", "exec loginctl terminate-user \"$USER\"" ] },
        { label: "Shutdown", command: [ "systemctl", "poweroff" ] },
        { label: "Suspend", command: [ "systemctl", "suspend-then-hibernate" ] },
        { label: "Reboot", command: [ "systemctl", "reboot" ] }
    ]

    implicitWidth: 160
    implicitHeight: 216

    onOpening: selectedAction = 0

    function run(index) {
        closeAnimated();
        if (index === 0) lockRequested();
        else Quickshell.execDetached(actions[index].command);
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
                popup.selectedAction = event.key - Qt.Key_1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                popup.selectedAction = (popup.selectedAction + popup.actions.length - 1)
                    % popup.actions.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                popup.selectedAction = (popup.selectedAction + 1) % popup.actions.length;
                event.accepted = true;
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    && popup.selectedAction >= 0) {
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
                ActionButton {
                    required property var modelData
                    required property int index
                    theme: popup.theme
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    text: modelData.label
                    trailingText: String(index + 1)
                    checked: popup.selectedAction === index
                    onClicked: popup.run(index)
                }
            }
        }
    }
}
