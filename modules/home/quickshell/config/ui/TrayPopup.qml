import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: popup
    required property QtObject theme
    required property var colors
    required property Item anchorItem
    property bool expanded: false
    property bool slideOnClose: true

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6
    implicitWidth: 270
    implicitHeight: Math.min(320, Math.max(46, 16 + SystemTray.items.values.length * 34))
    color: "transparent"
    grabFocus: true
    visible: false

    function toggle() {
        if (visible && expanded) closeAnimated();
        else {
            closeTimer.stop();
            slideOnClose = true;
            visible = true;
            Qt.callLater(() => {
                expanded = true;
                card.forceActiveFocus();
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
    onVisibleChanged: if (!visible) expanded = false
    Timer { id: closeTimer; interval: theme.notificationSlideDuration; onTriggered: popup.visible = false }

    Rectangle {
        id: card
        width: parent.width
        height: parent.height
        y: popup.expanded || !popup.slideOnClose ? 0 : -height - 8
        opacity: popup.expanded ? 1 : 0
        focus: true
        Keys.onEscapePressed: popup.closeFade()
        color: colors.surface
        border.width: 1
        border.color: colors.border
        clip: true
        Behavior on y { NumberAnimation { duration: theme.notificationSlideDuration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 4
                visible: SystemTray.items.values.length === 0
                text: "No tray items"
                verticalAlignment: Text.AlignVCenter
                color: colors.foreground
                font.family: theme.fontFamily
                font.pixelSize: theme.fontPixelSize
            }
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: trayItems.implicitHeight
                Column {
                    id: trayItems
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: SystemTray.items
                        Rectangle {
                            id: row
                            required property QtObject modelData
                            readonly property var quitEntry: menuOpener.children.values.find(entry =>
                                entry.enabled && !entry.hasChildren && /^(quit|exit)(\s+.*)?$/i.test(entry.text.replace(/&/g, "").trim())) ?? null
                            width: trayItems.width
                            height: 32
                            color: hover.hovered ? colors.overlay : "transparent"

                            function openMenu(item) {
                                if (!modelData.hasMenu) return;
                                const point = item.mapToItem(popup.contentItem, item.width / 2, item.height);
                                modelData.display(popup, Math.round(point.x), Math.round(point.y));
                            }
                            function quitApp() {
                                if (quitEntry) quitEntry.triggered();
                                else Quickshell.execDetached([
                                    "python3", Quickshell.shellPath("utils/quit-tray-item.py"), modelData.id
                                ]);
                                popup.closeAnimated();
                            }

                            QsMenuOpener {
                                id: menuOpener
                                menu: row.modelData.hasMenu ? row.modelData.menu : null
                            }
                            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                            MouseArea {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width - 52
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) row.modelData.secondaryActivate();
                                    else if (mouse.button === Qt.RightButton || row.modelData.onlyMenu) row.openMenu(row);
                                    else {
                                        row.modelData.activate();
                                        popup.closeAnimated();
                                    }
                                }
                                onWheel: wheel => row.modelData.scroll(wheel.angleDelta.y, false)
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 5
                                anchors.rightMargin: 5
                                spacing: 7
                                Image {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    source: row.modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.title || row.modelData.tooltipTitle || row.modelData.id
                                    color: colors.foreground
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontPixelSize
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: menuGlyph
                                    visible: row.modelData.hasMenu
                                    text: "󰇙"
                                    color: menuHover.hovered ? colors.foreground : colors.mutedForeground
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontPixelSize + 2
                                    Layout.preferredWidth: 18
                                    Layout.fillHeight: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    HoverHandler { id: menuHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: row.openMenu(menuGlyph)
                                    }
                                }
                                Text {
                                    text: "󰅖"
                                    color: quitHover.hovered ? colors.critical : colors.mutedForeground
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontPixelSize + 2
                                    Layout.preferredWidth: 18
                                    Layout.fillHeight: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    HoverHandler { id: quitHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: row.quitApp()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
