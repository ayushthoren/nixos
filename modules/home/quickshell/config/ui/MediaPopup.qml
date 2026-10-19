import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.Mpris

import "components"

AnimatedPopup {
    id: popup
    property var player: null
    property int selectedPlayerIndex: -1
    readonly property var currentPlayer: selectedPlayerIndex >= 0 ? (Mpris.players.values[selectedPlayerIndex] || player) : player
    property real shownPosition: 0

    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    implicitWidth: 350
    implicitHeight: Math.ceil(content.implicitHeight)

    onAboutToOpen: {
        selectedPlayerIndex = -1;
        shownPosition = currentPlayer?.position ?? 0;
    }
    Timer {
        interval: 1000
        repeat: true
        running: popup.visible && !!popup.currentPlayer?.isPlaying
        onTriggered: popup.shownPosition = popup.currentPlayer?.position ?? 0
    }
    onCurrentPlayerChanged: shownPosition = currentPlayer?.position ?? 0

    Connections {
        target: popup.currentPlayer
        function onPositionChanged() {
            popup.shownPosition = popup.currentPlayer?.position ?? 0;
        }
        function onTrackChanged() {
            popup.shownPosition = 0;
        }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 116
            Layout.fillHeight: true
            color: popup.colors.overlay
            Image {
                id: artImage
                anchors.fill: parent
                source: popup.currentPlayer?.trackArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            ThemedText {
                theme: popup.theme
                anchors.centerIn: parent
                visible: !artImage.visible
                text: "♫"
                font.pixelSize: 28
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                ThemedText {
                    theme: popup.theme
                    Layout.fillWidth: true
                    text: popup.currentPlayer?.trackTitle || "Nothing playing"

                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
                ThemedText {
                    theme: popup.theme
                    visible: Mpris.players.values.length > 1
                    text: "↻"
                    color: popup.colors.mutedForeground

                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.nextPlayer()
                    }
                }
            }

            ThemedText {
                theme: popup.theme
                Layout.fillWidth: true
                visible: text !== ""
                text: popup.currentPlayer?.trackAlbum || ""
                color: popup.colors.mutedForeground
                font.pixelSize: popup.theme.fontPixelSize - 1
                elide: Text.ElideRight
            }

            ThemedText {
                theme: popup.theme
                Layout.fillWidth: true
                visible: text !== ""
                text: popup.currentPlayer?.trackArtist || ""
                color: popup.colors.mutedForeground
                font.pixelSize: popup.theme.fontPixelSize - 1
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                ThemedText {
                    theme: popup.theme
                    text: popup.formatTime(popup.shownPosition)
                    color: popup.colors.mutedForeground

                    font.pixelSize: popup.theme.fontPixelSize - 2
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        color: Qt.rgba(popup.colors.foreground.r, popup.colors.foreground.g, popup.colors.foreground.b, 0.22)
                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.max(0, Math.min(1, popup.shownPosition / Math.max(1, popup.currentPlayer?.length || 0)))
                            color: popup.colors.activeSurface
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !!popup.currentPlayer?.canSeek && !!popup.currentPlayer?.positionSupported && !!popup.currentPlayer?.lengthSupported
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => popup.seekTo(mouse.x / width)
                        onPositionChanged: mouse => {
                            if (pressed)
                                popup.seekTo(mouse.x / width);
                        }
                    }
                }
                ThemedText {
                    theme: popup.theme
                    text: popup.formatTime(popup.currentPlayer?.length || 0)
                    color: popup.colors.mutedForeground

                    font.pixelSize: popup.theme.fontPixelSize - 2
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                ThemedText {
                    theme: popup.theme
                    visible: popup.currentPlayer?.shuffleSupported ?? false
                    text: "󰒝"
                    color: popup.currentPlayer?.shuffle ? popup.colors.activeSurface : popup.colors.mutedForeground

                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.currentPlayer.shuffle = !popup.currentPlayer.shuffle
                    }
                }
                ThemedText {
                    theme: popup.theme
                    text: "󰒮"
                    color: popup.currentPlayer?.canGoPrevious ? popup.colors.foreground : popup.colors.mutedForeground

                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (popup.currentPlayer?.canGoPrevious)
                            popup.currentPlayer.previous()
                    }
                }
                ThemedText {
                    theme: popup.theme
                    text: popup.currentPlayer?.isPlaying ? "󰏤" : "󰐊"
                    color: popup.currentPlayer?.canTogglePlaying ? popup.colors.foreground : popup.colors.mutedForeground

                    font.pixelSize: 22
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (popup.currentPlayer?.canTogglePlaying)
                            popup.currentPlayer.togglePlaying()
                    }
                }
                ThemedText {
                    theme: popup.theme
                    text: "󰒭"
                    color: popup.currentPlayer?.canGoNext ? popup.colors.foreground : popup.colors.mutedForeground

                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (popup.currentPlayer?.canGoNext)
                            popup.currentPlayer.next()
                    }
                }
                ThemedText {
                    theme: popup.theme
                    visible: popup.currentPlayer?.loopSupported ?? false
                    text: popup.currentPlayer?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                    color: popup.currentPlayer?.loopState !== MprisLoopState.None ? popup.colors.activeSurface : popup.colors.mutedForeground

                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.nextLoopState()
                    }
                }
            }
        }
    }

    function nextPlayer() {
        const players = Mpris.players.values;
        if (players.length < 2)
            return;
        const index = players.indexOf(currentPlayer);
        selectedPlayerIndex = (index + 1) % players.length;
        shownPosition = currentPlayer?.position || 0;
    }

    function seekTo(fraction) {
        if (!currentPlayer?.canSeek || !currentPlayer?.positionSupported || !currentPlayer?.lengthSupported)
            return;
        const position = Math.max(0, Math.min(currentPlayer.length, fraction * currentPlayer.length));
        shownPosition = position;
        currentPlayer.position = position;
    }

    function nextLoopState() {
        if (!currentPlayer?.loopSupported)
            return;
        currentPlayer.loopState = currentPlayer.loopState === MprisLoopState.None ? MprisLoopState.Playlist : currentPlayer.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(seconds || 0));
        return `${Math.floor(value / 60)}:${String(value % 60).padStart(2, "0")}`;
    }
}
