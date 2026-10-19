import QtQuick

import Quickshell

import "../.."

PopupWindow {
    id: root
    required property Theme theme
    required property var colors
    required property Item anchorItem
    default property alias contents: card.data
    property Item focusItem: card
    property bool expanded: false
    property bool slideOnClose: true
    property bool opening: false
    signal aboutToOpen

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: theme.popupMargin
    color: "transparent"
    grabFocus: true
    visible: false

    function toggle() {
        if (opening || (visible && expanded))
            closeAnimated();
        else {
            closeTimer.stop();
            aboutToOpen();
            slideOnClose = true;
            opening = true;
            visible = true;
            Qt.callLater(() => {
                // A close or external hide can arrive before this deferred open.
                if (!opening)
                    return;
                opening = false;
                if (!visible)
                    return;
                expanded = true;
                focusItem.forceActiveFocus();
            });
        }
    }
    function closeAnimated() {
        close(true);
    }
    function closeFade() {
        close(false);
    }
    function close(slide) {
        if (!opening && (!visible || !expanded))
            return;
        opening = false;
        slideOnClose = slide;
        expanded = false;
        closeTimer.interval = slide ? theme.notificationSlideDuration : theme.popupFadeDuration;
        closeTimer.restart();
    }
    onVisibleChanged: {
        if (!visible) {
            opening = false;
            expanded = false;
            closeTimer.stop();
        }
    }

    // Keep infrastructure out of the default content property.
    property Timer closeTimer: Timer {
        onTriggered: root.visible = false
    }

    data: Rectangle {
        id: card
        parent: root.contentItem
        width: parent.width
        height: parent.height
        y: root.expanded || !root.slideOnClose ? 0 : -height - root.theme.popupSlideMargin
        opacity: root.expanded ? 1 : 0
        focus: true
        Keys.onEscapePressed: root.closeFade()
        color: root.colors.surface
        border.width: 1
        border.color: root.colors.border
        clip: true
        Behavior on y {
            NumberAnimation {
                duration: root.theme.notificationSlideDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.theme.popupFadeDuration
                easing.type: Easing.OutQuad
            }
        }
    }
}
