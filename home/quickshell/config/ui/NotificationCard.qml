import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.Notifications

import ".."
import "components"

Rectangle {
    id: root

    required property Theme theme
    required property Notification notification
    required property var colors
    signal removeRequested

    property bool visibleState: false
    property bool closing: false
    property string closeMode: ""
    property var closeAction: null
    readonly property real popupHeight: content.implicitHeight + (root.theme.notificationPadding * 2)
    readonly property bool hasSummary: root.notification.summary !== ""
    readonly property bool hasBody: root.notification.body !== ""
    readonly property string imageSource: resolveSource(root.notification.hints?.["image-path"] || root.notification.hints?.image_path || root.notification.image)
    readonly property string iconSource: resolveSource(root.notification.appIcon)
    readonly property bool hasImage: imageSource !== "" && imageProbe.status === Image.Ready
    readonly property bool avatarImage: hasImage && imageProbe.sourceSize.width <= 256 && imageProbe.sourceSize.height <= 256 && imageProbe.sourceSize.width / Math.max(1, imageProbe.sourceSize.height) > 0.75 && imageProbe.sourceSize.width / Math.max(1, imageProbe.sourceSize.height) < 1.33
    readonly property bool hasIcon: iconSource !== "" && appIcon.status === Image.Ready
    property real remainingMs: timeoutMs
    property real lastTickMs: 0
    readonly property int timeoutMs: {
        if (root.notification.expireTimeout > 0) {
            return Math.round(root.notification.expireTimeout);
        }

        if (root.notification.urgency === NotificationUrgency.Critical)
            return 10000;
        return root.notification.urgency === NotificationUrgency.Low ? 4000 : 6000;
    }

    height: popupHeight
    x: visibleState && !closing ? 0 : width + root.theme.notificationSlideDistance
    opacity: visibleState && !closing ? 1 : 0
    color: root.colors.surface
    border.width: 1
    border.color: accentColor()

    function resolveSource(value) {
        const source = String(value || "");
        if (!source)
            return "";
        if (source.startsWith("/"))
            return "file://" + source;
        if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(source))
            return source;
        const home = Quickshell.env("HOME") || "";
        if (source.startsWith("~/"))
            return "file://" + home + source.slice(1);
        if (source.includes("/") || /\.(png|jpe?g|webp|gif|svg)$/i.test(source)) {
            return "file://" + home + "/" + source;
        }
        return Quickshell.hasThemeIcon(source) ? Quickshell.iconPath(source, true) : "";
    }

    function enter() {
        restartTimeout();
        visibleState = true;
    }
    function restartTimeout() {
        finishTimer.stop();
        closing = false;
        closeMode = "";
        closeAction = null;
        visibleState = true;
        remainingMs = timeoutMs;
        lastTickMs = Date.now();
    }

    Behavior on x {
        NumberAnimation {
            duration: root.theme.notificationSlideDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutQuad
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: root.theme.notificationSlideDuration + 50
            easing.type: Easing.OutCubic
        }
    }

    function accentColor() {
        if (root.notification.urgency === NotificationUrgency.Critical) {
            return root.colors.critical;
        }

        if (root.notification.urgency === NotificationUrgency.Low) {
            return root.colors.low;
        }

        return root.colors.border;
    }

    function beginClose(mode, action) {
        if (closing) {
            return;
        }

        closing = true;
        closeMode = mode;
        closeAction = action || null;
        visibleState = false;
        finishTimer.restart();
    }

    function closeNotification(fromTimeout) {
        beginClose(fromTimeout ? "expire" : "dismiss", null);
    }

    function invokeAction(action) {
        if (root.notification.resident) {
            action.invoke();
            return;
        }

        beginClose("action", action);
    }

    function sendReply() {
        if (!root.notification.hasInlineReply || !replyField.text.trim())
            return;
        const reply = replyField.text;
        replyField.clear();
        root.notification.sendInlineReply(reply);
    }

    function finishClose() {
        if (closeMode === "expire") {
            root.notification.expire();
        } else if (closeMode === "dismiss") {
            root.notification.dismiss();
        } else if (closeMode === "action" && closeAction) {
            closeAction.invoke();
        }

        closeMode = "";
        closeAction = null;
    }

    Timer {
        id: countdown
        interval: 100
        repeat: true
        running: root.visibleState && !root.closing && !hoverHandler.hovered
        onTriggered: {
            const now = Date.now();
            root.remainingMs = Math.max(0, root.remainingMs - (now - root.lastTickMs));
            root.lastTickMs = now;
            if (root.remainingMs <= 0)
                root.closeNotification(true);
        }
    }

    Timer {
        id: finishTimer
        interval: root.theme.notificationSlideDuration
        onTriggered: root.finishClose()
    }

    Connections {
        target: root.notification

        function onClosed() {
            root.removeRequested();
        }
    }

    HoverHandler {
        id: hoverHandler
        blocking: false
        onHoveredChanged: root.lastTickMs = Date.now()
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.theme.notificationPadding
        spacing: root.theme.notificationSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: root.theme.notificationSpacing

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                visible: root.hasIcon || root.avatarImage || !root.hasImage
                color: root.accentColor()

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: root.avatarImage ? 30 : 20
                    height: width
                    source: root.avatarImage ? root.imageSource : root.iconSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }

                ThemedText {
                    theme: root.theme
                    anchors.centerIn: parent
                    visible: !root.hasIcon && !root.avatarImage
                    text: root.notification.urgency === NotificationUrgency.Critical ? "!" : "•"
                    color: root.colors.activeForeground
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                ThemedText {
                    theme: root.theme
                    Layout.fillWidth: true
                    text: root.hasSummary ? root.notification.summary : root.notification.appName

                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                ThemedText {
                    theme: root.theme
                    Layout.fillWidth: true
                    visible: root.hasSummary && root.notification.appName !== ""
                    text: root.notification.appName
                    color: root.colors.mutedForeground

                    font.pixelSize: root.theme.fontPixelSize - 1
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }

            Item {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: closeLabel.implicitWidth
                Layout.preferredHeight: closeLabel.implicitHeight

                ThemedText {
                    id: closeLabel
                    theme: root.theme
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: root.colors.mutedForeground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeNotification(false)
                }
            }
        }

        ThemedText {
            theme: root.theme
            Layout.fillWidth: true
            visible: root.hasBody
            text: root.notification.body

            wrapMode: Text.Wrap
            maximumLineCount: 8
            elide: Text.ElideRight
            textFormat: Text.RichText
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        Image {
            id: imageProbe
            visible: false
            source: root.imageSource
            asynchronous: true
        }

        Image {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 160 : 0
            visible: root.hasImage && !root.avatarImage
            source: root.imageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            clip: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.notification.hasInlineReply
            spacing: root.theme.notificationSpacing

            TextField {
                id: replyField
                Layout.fillWidth: true
                font.family: root.theme.fontFamily
                placeholderText: root.notification.inlineReplyPlaceholder || "Reply"
                color: root.colors.foreground
                font.pixelSize: root.theme.fontPixelSize
                background: Rectangle {
                    color: root.colors.overlay
                    border.color: root.colors.border
                }
                onAccepted: root.sendReply()
            }

            ThemedText {
                theme: root.theme
                text: "Send"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sendReply()
                }
            }
        }

        NotificationActions {
            Layout.fillWidth: true
            theme: root.theme
            colors: root.colors
            notification: root.notification
            onInvoked: action => root.invokeAction(action)
        }
    }

    Rectangle {
        z: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        height: 2
        color: Qt.rgba(root.colors.foreground.r, root.colors.foreground.g, root.colors.foreground.b, 0.12)

        Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(1, root.remainingMs / Math.max(1, root.timeoutMs)))
            color: root.colors.activeSurface
            Behavior on width {
                NumberAnimation {
                    duration: countdown.interval
                    easing.type: Easing.Linear
                }
            }
        }
    }
}
