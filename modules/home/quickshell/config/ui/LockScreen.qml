import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

import ".."
import "components"

Scope {
    id: root

    required property Theme theme

    property string hostname: ""
    property string pendingPassword: ""
    property string statusMessage: ""
    property bool authenticating: false
    property bool contentVisible: false
    property bool backgroundVisible: false
    property bool preparingLock: false
    property bool transitionVisible: false
    property bool exiting: false
    property bool wallpaperReady: false
    property string wallpaperSource: ""
    property real transitionOpacity: 0

    readonly property int animationDuration: 350
    readonly property int backgroundAnimationDuration: 450
    readonly property var colors: root.theme.palette
    readonly property string identity: `${Quickshell.env("USER") || "user"}@${hostname || "localhost"}`

    signal resetInput

    function lock() {
        if (sessionLock.locked || preparingLock)
            return;

        unlockAnimation.stop();
        contentVisible = false;
        backgroundVisible = false;
        preparingLock = true;
        transitionVisible = false;
        transitionOpacity = 0;
        exiting = false;
        authenticating = false;
        pendingPassword = "";
        statusMessage = "";
        wallpaperReady = false;
        wallpaperSource = "";
        refreshWallpaper();
        preparationTimeout.restart();
    }

    function finishLockPreparation() {
        if (!preparingLock)
            return;
        preparationTimeout.stop();
        preparingLock = false;
        transitionVisible = true;
        backgroundVisible = true;
        Qt.callLater(() => {
            root.transitionOpacity = 1;
            entryTransitionTimer.restart();
        });
    }

    function refreshWallpaper() {
        wallpaperQuery.running = false;
        wallpaperQuery.running = true;
    }

    function setWallpaperFromQuery(output) {
        const match = output.match(/currently displaying:\s*image:\s*(.+)\s*$/m);
        if (!match)
            return;

        wallpaperSource = "";
        const path = match[1].trim();
        Qt.callLater(() => wallpaperSource = encodeURI("file://" + path));
    }

    function authenticate(candidate) {
        if (!candidate || authenticating)
            return;

        pendingPassword = candidate;
        statusMessage = "";
        authenticating = true;
        if (!pam.start())
            authenticationFailed("Authentication unavailable");
    }

    function authenticationFailed(message) {
        authenticating = false;
        pendingPassword = "";
        statusMessage = message;
        resetInput();
    }

    Process {
        command: ["hostname"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hostname = text.trim()
        }
    }

    Process {
        id: wallpaperQuery
        command: ["awww", "query"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.setWallpaperFromQuery(text)
        }
    }

    Image {
        source: root.wallpaperSource
        asynchronous: true
        visible: false

        onStatusChanged: {
            root.wallpaperReady = status === Image.Ready;
            if (root.wallpaperReady && root.preparingLock)
                root.finishLockPreparation();
        }
    }

    Timer {
        id: preparationTimeout
        interval: 1000
        onTriggered: root.finishLockPreparation()
    }

    Timer {
        id: entryTransitionTimer
        interval: root.backgroundAnimationDuration + 20
        onTriggered: sessionLock.locked = true
    }

    Timer {
        id: exitTransitionTimer
        interval: root.backgroundAnimationDuration + 20
        onTriggered: {
            root.transitionVisible = false;
            root.exiting = false;
            root.authenticating = false;
        }
    }

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        visible: root.transitionVisible

        Image {
            id: transitionWallpaper
            anchors.fill: parent
            source: root.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: transitionWallpaper
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            autoPaddingEnabled: false
            opacity: root.transitionOpacity

            Behavior on opacity {
                NumberAnimation {
                    duration: root.backgroundAnimationDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (responseRequired)
                respond(root.pendingPassword);
            else if (messageIsError)
                root.statusMessage = message;
        }
        onCompleted: result => {
            root.pendingPassword = "";
            if (result === PamResult.Success) {
                root.contentVisible = false;
                root.exiting = true;
                root.transitionOpacity = 1;
                root.transitionVisible = true;
                unlockAnimation.restart();
            } else {
                root.authenticationFailed("Authentication failed");
            }
        }
        onError: root.authenticationFailed("Authentication unavailable")
    }

    SequentialAnimation {
        id: unlockAnimation

        PauseAnimation {
            duration: root.animationDuration + 20
        }
        ScriptAction {
            script: sessionLock.locked = false
        }
    }

    WlSessionLock {
        id: sessionLock

        onSecureChanged: {
            if (secure) {
                root.transitionVisible = false;
                root.resetInput();
                Qt.callLater(() => {
                    root.contentVisible = true;
                    if (root.wallpaperReady)
                        root.backgroundVisible = true;
                });
            } else {
                root.contentVisible = false;
                root.backgroundVisible = false;
                if (root.exiting) {
                    root.transitionVisible = true;
                    Qt.callLater(() => {
                        root.transitionOpacity = 0;
                        exitTransitionTimer.restart();
                    });
                }
            }
        }

        WlSessionLockSurface {
            color: "transparent"

            HoverHandler {
                cursorShape: Qt.BlankCursor
            }

            Image {
                id: wallpaperImage
                anchors.fill: parent
                source: root.wallpaperSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            MultiEffect {
                anchors.fill: parent
                source: wallpaperImage
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                autoPaddingEnabled: false
                opacity: root.backgroundVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.backgroundAnimationDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Item {
                id: content
                anchors.fill: parent
                opacity: root.contentVisible ? 1 : 0
                y: root.contentVisible ? 0 : -14

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.InOutCubic
                    }
                }

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(360, parent.width - 40)
                    spacing: 0

                    ThemedText {
                        theme: root.theme
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "h:mm AP")
                        font.pixelSize: 48
                        font.bold: true
                    }
                    ThemedText {
                        theme: root.theme
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 2
                        text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
                        color: root.colors.mutedForeground
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        Layout.topMargin: 30
                        clip: true
                        color: root.colors.surface
                        border.width: 1
                        border.color: passwordInput.activeFocus ? root.colors.activeSurface : root.colors.border

                        ThemedText {
                            theme: root.theme
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordInput.text.length === 0
                            text: "Password"
                            color: root.colors.mutedForeground
                        }
                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.colors.foreground
                            selectionColor: root.colors.activeSurface
                            selectedTextColor: root.colors.activeForeground
                            font.pixelSize: root.theme.fontPixelSize * 1.5
                            font.family: root.theme.fontFamily
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            enabled: !root.authenticating
                            focus: true
                            onAccepted: root.authenticate(text)
                            Component.onCompleted: forceActiveFocus()

                            Connections {
                                target: root
                                function onResetInput() {
                                    passwordInput.clear();
                                    passwordInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                    ThemedText {
                        theme: root.theme
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        text: root.identity
                        color: root.colors.mutedForeground
                    }
                    ThemedText {
                        theme: root.theme
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        Layout.preferredHeight: 18
                        opacity: root.authenticating || root.statusMessage !== "" ? 1 : 0
                        text: root.authenticating ? "Authenticating…" : root.statusMessage
                        color: root.statusMessage !== "" ? root.colors.critical : root.colors.mutedForeground
                        font.pixelSize: root.theme.fontPixelSize - 1
                    }
                }
            }
        }
    }
}
