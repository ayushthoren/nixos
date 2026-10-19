import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.SystemTray

import "components"

AnimatedPopup {
    id: popup

    implicitWidth: 270
    implicitHeight: Math.min(320, Math.max(46, 16 + SystemTray.items.values.length * 34))

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6
        ThemedText {
            theme: popup.theme
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 4
            visible: SystemTray.items.values.length === 0
            text: "No tray items"
            verticalAlignment: Text.AlignVCenter
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
                        readonly property var quitEntry: menuOpener.children.values.find(entry => entry.enabled && !entry.hasChildren && /^(quit|exit)(\s+.*)?$/i.test(entry.text.replace(/&/g, "").trim())) ?? null
                        width: trayItems.width
                        height: 32
                        color: hover.hovered ? popup.colors.overlay : "transparent"

                        function openMenu(item) {
                            if (!modelData.hasMenu)
                                return;
                            const point = item.mapToItem(popup.contentItem, item.width / 2, item.height);
                            modelData.display(popup, Math.round(point.x), Math.round(point.y));
                        }
                        function quitApp() {
                            if (quitEntry)
                                quitEntry.triggered();
                            else
                                Quickshell.execDetached(["python3", Quickshell.shellPath("utils/quit-tray-item.py"), modelData.id]);
                            popup.closeAnimated();
                        }

                        QsMenuOpener {
                            id: menuOpener
                            menu: row.modelData.hasMenu ? row.modelData.menu : null
                        }
                        HoverHandler {
                            id: hover
                            cursorShape: Qt.PointingHandCursor
                        }
                        MouseArea {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width - 52
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton)
                                    row.modelData.secondaryActivate();
                                else if (mouse.button === Qt.RightButton || row.modelData.onlyMenu)
                                    row.openMenu(row);
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
                            ThemedText {
                                theme: popup.theme
                                Layout.fillWidth: true
                                text: row.modelData.title || row.modelData.tooltipTitle || row.modelData.id

                                elide: Text.ElideRight
                            }
                            ThemedText {
                                id: menuGlyph
                                theme: popup.theme
                                visible: row.modelData.hasMenu
                                text: "󰇙"
                                color: menuHover.hovered ? popup.colors.foreground : popup.colors.mutedForeground

                                font.pixelSize: popup.theme.fontPixelSize + 2
                                Layout.preferredWidth: 18
                                Layout.fillHeight: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                HoverHandler {
                                    id: menuHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: row.openMenu(menuGlyph)
                                }
                            }
                            ThemedText {
                                theme: popup.theme
                                text: "󰅖"
                                color: quitHover.hovered ? popup.colors.critical : popup.colors.mutedForeground

                                font.pixelSize: popup.theme.fontPixelSize + 2
                                Layout.preferredWidth: 18
                                Layout.fillHeight: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                HoverHandler {
                                    id: quitHover
                                }
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
