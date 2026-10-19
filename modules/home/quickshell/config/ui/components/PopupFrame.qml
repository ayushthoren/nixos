import QtQuick
import Quickshell

PopupWindow {
    id: frame
    required property QtObject theme
    property var colors: theme.palette
    required property Item anchorItem
    property Item focusTarget: surface
    property bool alignRight: true
    property bool expanded: false
    property bool slideOnClose: true
    default property alias body: surface.data
    signal opening()
    signal dismissRequested(bool fade)

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | (alignRight ? Edges.Right : Edges.Left)
    anchor.gravity: Edges.Bottom | (alignRight ? Edges.Left : Edges.Right)
    anchor.margins.top: theme.popupGap
    color: "transparent"
    grabFocus: true
    visible: false

    function toggle() {
        if (visible && expanded) dismissRequested(false);
        else open();
    }
    function open() {
        closeTimer.stop();
        slideOnClose = true;
        opening();
        visible = true;
        Qt.callLater(() => {
            if (!visible) return;
            expanded = true;
            focusTarget.forceActiveFocus();
        });
    }
    function hideAnimated(fade = false) {
        if (!visible) return;
        slideOnClose = !fade;
        expanded = false;
        closeTimer.interval = fade ? theme.fadeDuration : theme.notificationSlideDuration;
        closeTimer.restart();
    }
    function closeAnimated() { dismissRequested(false); }
    function closeFade() { dismissRequested(true); }
    onDismissRequested: fade => hideAnimated(fade)
    onVisibleChanged: if (!visible) expanded = false

    // Explicit data parent: the default property belongs to the animated surface.
    data: [
        Timer {
            id: closeTimer
            onTriggered: frame.visible = false
        },
        Rectangle {
            id: surface
            width: frame.contentItem.width
            height: frame.contentItem.height
            y: frame.expanded || !frame.slideOnClose ? 0 : -height - theme.popupGap - 2
            opacity: frame.expanded ? 1 : 0
            color: frame.colors.surface
            border.width: 1
            border.color: frame.colors.border
            radius: theme.surfaceRadius
            clip: true
            focus: true
            Keys.onEscapePressed: frame.dismissRequested(true)
            Behavior on y { NumberAnimation { duration: frame.theme.notificationSlideDuration; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: frame.theme.fadeDuration; easing.type: Easing.OutQuad } }
        }
    ]
}
