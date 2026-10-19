import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property QtObject theme
    required property QtObject notification
    required property var colors
    signal removeRequested()

    property bool visibleState: false
    property bool closing: false
    property string closeMode: ""
    property var closeAction: null
    readonly property real popupHeight: content.implicitHeight + (theme.notificationPadding * 2)
    readonly property bool hasSummary: notification.summary !== ""
    readonly property bool hasBody: notification.body !== ""
    readonly property string imageSource: resolveSource(
        notification.hints?.["image-path"] || notification.hints?.image_path || notification.image)
    readonly property string iconSource: resolveSource(notification.appIcon)
    readonly property bool hasImage: imageSource !== "" && content.imageProbe.status === Image.Ready
    readonly property bool avatarImage: hasImage && content.imageProbe.sourceSize.width <= 256
        && content.imageProbe.sourceSize.height <= 256
        && content.imageProbe.sourceSize.width / Math.max(1, content.imageProbe.sourceSize.height) > 0.75
        && content.imageProbe.sourceSize.width / Math.max(1, content.imageProbe.sourceSize.height) < 1.33
    readonly property bool hasIcon: iconSource !== "" && content.appIcon.status === Image.Ready
    property real remainingMs: timeoutMs
    property real lastTickMs: 0
    readonly property int timeoutMs: {
        if (notification.expireTimeout > 0) {
            return Math.round(notification.expireTimeout);
        }

        if (notification.urgency === NotificationUrgency.Critical) return 10000;
        return notification.urgency === NotificationUrgency.Low ? 4000 : 6000;
    }

    height: popupHeight
    x: visibleState && !closing ? 0 : width + theme.notificationSlideDistance
    opacity: visibleState && !closing ? 1 : 0
    color: colors.surface
    border.width: 1
    border.color: accentColor()

    function resolveSource(value) {
        const source = String(value || "");
        if (!source) return "";
        if (source.startsWith("/")) return "file://" + source;
        if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(source)) return source;
        const home = Quickshell.env("HOME") || "";
        if (source.startsWith("~/")) return "file://" + home + source.slice(1);
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
        remainingMs = timeoutMs;
        lastTickMs = Date.now();
    }

    Behavior on x {
        NumberAnimation {
            duration: theme.notificationSlideDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 130; easing.type: Easing.OutQuad }
    }

    Behavior on y {
        NumberAnimation {
            duration: theme.notificationSlideDuration + 50
            easing.type: Easing.OutCubic
        }
    }

    function accentColor() {
        if (notification.urgency === NotificationUrgency.Critical) {
            return colors.critical;
        }

        if (notification.urgency === NotificationUrgency.Low) {
            return colors.low;
        }

        return colors.border;
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
        if (notification.resident) {
            action.invoke();
            return;
        }

        beginClose("action", action);
    }

    function sendReply() {
        if (!notification.hasInlineReply || !content.replyField.text.trim()) return;
        const reply = content.replyField.text;
        content.replyField.clear();
        notification.sendInlineReply(reply);
    }

    function finishClose() {
        if (closeMode === "expire") {
            notification.expire();
        } else if (closeMode === "dismiss") {
            notification.dismiss();
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
            if (root.remainingMs <= 0) root.closeNotification(true);
        }
    }

    Timer {
        id: finishTimer
        interval: theme.notificationSlideDuration
        onTriggered: root.finishClose()
    }

    Connections {
        target: notification

        function onClosed() {
            root.removeRequested();
        }
    }

    HoverHandler {
        id: hoverHandler
        blocking: false
        onHoveredChanged: root.lastTickMs = Date.now()
    }

    NotificationContent {
        id: content
        controller: root
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
            Behavior on width { NumberAnimation { duration: countdown.interval; easing.type: Easing.Linear } }
        }
    }
}
