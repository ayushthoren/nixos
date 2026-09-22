import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: popup
    required property QtObject theme
    required property var colors
    required property Item anchorItem
    property var player: null
    property int selectedPlayerIndex: -1
    readonly property var currentPlayer: selectedPlayerIndex >= 0
        ? (Mpris.players.values[selectedPlayerIndex] || player) : player
    property bool expanded: false
    property bool slideOnClose: true
    property real shownPosition: 0

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.top: 6
    implicitWidth: 350
    implicitHeight: Math.ceil(content.implicitHeight)
    color: "transparent"
    grabFocus: true
    visible: false

    function toggle() {
        if (visible && expanded) closeAnimated();
        else {
            closeTimer.stop();
            selectedPlayerIndex = -1;
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

    Timer {
        id: closeTimer
        interval: theme.notificationSlideDuration
        onTriggered: popup.visible = false
    }
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
                Text {
                    anchors.centerIn: parent
                    visible: !artImage.visible
                    text: "♫"
                    color: colors.foreground
                    font.family: theme.fontFamily
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
                    Text {
                        Layout.fillWidth: true
                        text: popup.currentPlayer?.trackTitle || "Nothing playing"
                        color: colors.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontPixelSize
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 2
                    }
                    Text {
                        visible: Mpris.players.values.length > 1
                        text: "↻"
                        color: colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 18
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.nextPlayer()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: popup.currentPlayer?.trackAlbum || ""
                    color: colors.mutedForeground
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontPixelSize - 1
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: popup.currentPlayer?.trackArtist || ""
                    color: colors.mutedForeground
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontPixelSize - 1
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Text {
                        text: popup.formatTime(popup.shownPosition)
                        color: colors.mutedForeground
                        font.family: theme.fontFamily
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
                    Text {
                        text: popup.formatTime(popup.currentPlayer?.length || 0)
                        color: colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontPixelSize - 2
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    Text {
                        visible: popup.currentPlayer?.shuffleSupported ?? false
                        text: "󰒝"
                        color: popup.currentPlayer?.shuffle ? colors.activeSurface : colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.currentPlayer.shuffle = !popup.currentPlayer.shuffle }
                    }
                    Text {
                        text: "󰒮"
                        color: popup.currentPlayer?.canGoPrevious ? colors.foreground : colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 20
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (popup.currentPlayer?.canGoPrevious) popup.currentPlayer.previous() }
                    }
                    Text {
                        text: popup.currentPlayer?.isPlaying ? "󰏤" : "󰐊"
                        color: popup.currentPlayer?.canTogglePlaying ? colors.foreground : colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 22
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (popup.currentPlayer?.canTogglePlaying) popup.currentPlayer.togglePlaying() }
                    }
                    Text {
                        text: "󰒭"
                        color: popup.currentPlayer?.canGoNext ? colors.foreground : colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 20
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (popup.currentPlayer?.canGoNext) popup.currentPlayer.next() }
                    }
                    Text {
                        visible: popup.currentPlayer?.loopSupported ?? false
                        text: popup.currentPlayer?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                        color: popup.currentPlayer?.loopState !== MprisLoopState.None ? colors.activeSurface : colors.mutedForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.nextLoopState() }
                    }
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
