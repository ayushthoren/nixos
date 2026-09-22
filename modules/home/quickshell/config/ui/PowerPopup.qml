import Quickshell
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: popup
    required property QtObject theme
    required property var colors
    required property Item anchorItem
    signal lockRequested()
    property bool expanded: false
    property bool slideOnClose: true
    property int selectedAction: 0

    readonly property var actions: [
        { label: "Lock", command: null },
        { label: "Hibernate", command: [ "systemctl", "hibernate" ] },
        { label: "Logout", command: [ "sh", "-c", "exec loginctl terminate-user \"$USER\"" ] },
        { label: "Shutdown", command: [ "systemctl", "poweroff" ] },
        { label: "Suspend", command: [ "systemctl", "suspend-then-hibernate" ] },
        { label: "Reboot", command: [ "systemctl", "reboot" ] }
    ]

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6
    implicitWidth: 160
    implicitHeight: 216
    color: "transparent"
    grabFocus: true
    visible: false

    function toggle() {
        if (visible && expanded) closeAnimated();
        else {
            closeTimer.stop();
            selectedAction = 0;
            slideOnClose = true;
            visible = true;
            Qt.callLater(() => {
                expanded = true;
                keyHandler.forceActiveFocus();
            });
        }
    }
    function closeAnimated() {
        if (!visible || !expanded) return;
        slideOnClose = true;
        expanded = false;
        closeTimer.interval = theme.notificationSlideDuration;
        closeTimer.restart();
    }
    function closeFade() {
        if (!visible || !expanded) return;
        slideOnClose = false;
        expanded = false;
        closeTimer.interval = 140;
        closeTimer.restart();
    }
    function run(index) {
        closeAnimated();
        if (index === 0) lockRequested();
        else Quickshell.execDetached(actions[index].command);
    }

    onVisibleChanged: if (!visible) expanded = false
    Timer { id: closeTimer; interval: theme.notificationSlideDuration; onTriggered: popup.visible = false }

    Rectangle {
        width: parent.width
        height: parent.height
        y: popup.expanded || !popup.slideOnClose ? 0 : -height - 8
        opacity: popup.expanded ? 1 : 0
        color: colors.surface
        border.width: 1
        border.color: colors.border
        clip: true
        Behavior on y { NumberAnimation { duration: theme.notificationSlideDuration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

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
                    Rectangle {
                        id: actionButton
                        required property var modelData
                        required property int index
                        readonly property bool highlighted: actionHover.hovered || popup.selectedAction === index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: highlighted ? colors.activeSurface : colors.overlay

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            Text {
                                Layout.fillWidth: true
                                text: actionButton.modelData.label
                                color: actionButton.highlighted ? colors.activeForeground : colors.foreground
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontPixelSize
                            }
                            Text {
                                text: String(actionButton.index + 1)
                                color: actionButton.highlighted ? colors.activeForeground : colors.mutedForeground
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontPixelSize - 1
                            }
                        }
                        HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
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
}
