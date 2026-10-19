import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "components"

PopupFrame {
    readonly property QtObject uiTheme: theme
    id: popup
    property var player: null
    property int selectedPlayerIndex: -1
    readonly property var currentPlayer: selectedPlayerIndex >= 0
        ? (Mpris.players.values[selectedPlayerIndex] || player) : player
    property real shownPosition: 0

    alignRight: false
    implicitWidth: 350
    implicitHeight: Math.ceil(content.implicitHeight)

    onOpening: selectedPlayerIndex = -1

    Timer {
        interval: 1000
        repeat: true
        running: popup.visible && !!popup.currentPlayer
        onTriggered: popup.shownPosition = popup.currentPlayer?.position ?? 0
    }
    Connections {
        target: popup.currentPlayer
        function onPositionChanged() { popup.shownPosition = popup.currentPlayer?.position ?? 0; }
        function onTrackChanged() { popup.shownPosition = 0; }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 116
            Layout.fillHeight: true
            color: colors.overlay
            Image {
                id: artImage
                anchors.fill: parent
                source: popup.currentPlayer?.trackArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            StyledText {
                theme: uiTheme
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
                StyledText {
                    theme: uiTheme
                    Layout.fillWidth: true
                    text: popup.currentPlayer?.trackTitle || "Nothing playing"
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
                StyledText {
                    theme: uiTheme
                    visible: Mpris.players.values.length > 1
                    text: "↻"
                    color: colors.mutedForeground
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.nextPlayer()
                    }
                }
            }

            StyledText {
                theme: uiTheme
                Layout.fillWidth: true
                visible: text !== ""
                text: popup.currentPlayer?.trackAlbum || ""
                color: colors.mutedForeground
                font.pixelSize: theme.fontPixelSize - 1
                elide: Text.ElideRight
            }

            StyledText {
                theme: uiTheme
                Layout.fillWidth: true
                visible: text !== ""
                text: popup.currentPlayer?.trackArtist || ""
                color: colors.mutedForeground
                font.pixelSize: theme.fontPixelSize - 1
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                StyledText {
                    theme: uiTheme
                    text: popup.formatTime(popup.shownPosition)
                    color: colors.mutedForeground
                    font.pixelSize: theme.fontPixelSize - 2
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.22)
                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.max(0, Math.min(1, popup.shownPosition / Math.max(1, popup.currentPlayer?.length || 0)))
                            color: colors.activeSurface
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !!popup.currentPlayer?.canSeek && !!popup.currentPlayer?.positionSupported && !!popup.currentPlayer?.lengthSupported
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => popup.seekTo(mouse.x / width)
                        onPositionChanged: mouse => {
                            if (pressed) popup.seekTo(mouse.x / width);
                        }
                    }
                }
                StyledText {
                    theme: uiTheme
                    text: popup.formatTime(popup.currentPlayer?.length || 0)
                    color: colors.mutedForeground
                    font.pixelSize: theme.fontPixelSize - 2
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                IconButton {
                    theme: uiTheme
                    visible: popup.currentPlayer?.shuffleSupported ?? false
                    text: "󰒝"
                    color: popup.currentPlayer?.shuffle ? colors.activeSurface : colors.mutedForeground
                    font.pixelSize: 18
                    onClicked: popup.currentPlayer.shuffle = !popup.currentPlayer.shuffle
                }
                IconButton {
                    theme: uiTheme
                    text: "󰒮"
                    color: popup.currentPlayer?.canGoPrevious ? colors.foreground : colors.mutedForeground
                    font.pixelSize: 20
                    onClicked: if (popup.currentPlayer?.canGoPrevious) popup.currentPlayer.previous()
                }
                IconButton {
                    theme: uiTheme
                    text: popup.currentPlayer?.isPlaying ? "󰏤" : "󰐊"
                    color: popup.currentPlayer?.canTogglePlaying ? colors.foreground : colors.mutedForeground
                    font.pixelSize: 22
                    onClicked: if (popup.currentPlayer?.canTogglePlaying) popup.currentPlayer.togglePlaying()
                }
                IconButton {
                    theme: uiTheme
                    text: "󰒭"
                    color: popup.currentPlayer?.canGoNext ? colors.foreground : colors.mutedForeground
                    font.pixelSize: 20
                    onClicked: if (popup.currentPlayer?.canGoNext) popup.currentPlayer.next()
                }
                IconButton {
                    theme: uiTheme
                    visible: popup.currentPlayer?.loopSupported ?? false
                    text: popup.currentPlayer?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                    color: popup.currentPlayer?.loopState !== MprisLoopState.None ? colors.activeSurface : colors.mutedForeground
                    font.pixelSize: 18
                    onClicked: popup.nextLoopState()
                }
            }
        }
    }
    function nextPlayer() {
        const players = Mpris.players.values;
        if (players.length < 2) return;
        const index = players.indexOf(currentPlayer);
        selectedPlayerIndex = (index + 1) % players.length;
        shownPosition = currentPlayer?.position || 0;
    }

    function seekTo(fraction) {
        if (!currentPlayer?.canSeek || !currentPlayer?.positionSupported || !currentPlayer?.lengthSupported) return;
        const position = Math.max(0, Math.min(currentPlayer.length, fraction * currentPlayer.length));
        shownPosition = position;
        currentPlayer.position = position;
    }

    function nextLoopState() {
        if (!currentPlayer?.loopSupported) return;
        currentPlayer.loopState = currentPlayer.loopState === MprisLoopState.None
            ? MprisLoopState.Playlist
            : currentPlayer.loopState === MprisLoopState.Playlist
                ? MprisLoopState.Track : MprisLoopState.None;
    }

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(seconds || 0));
        return `${Math.floor(value / 60)}:${String(value % 60).padStart(2, "0")}`;
    }
}
