import Quickshell
import Quickshell.Services.Notifications
import QtQuick

PanelWindow {
    id: root
    required property QtObject theme

    property var cards: []
    property int maxVisibleNotifications: 5
    property int stackHeight: 1

    anchors { top: true; right: true }
    margins {
        top: theme.barHeight + theme.notificationMargin
        right: theme.notificationMargin
    }
    implicitWidth: theme.notificationWidth + theme.notificationSlideDistance
    implicitHeight: screen ? Math.max(1, screen.height - margins.top - theme.notificationMargin) : 1080
    exclusionMode: ExclusionMode.Ignore
    mask: Region {
        x: root.width - root.theme.notificationWidth
        y: 0
        width: root.theme.notificationWidth
        height: root.stackHeight
    }
    color: "transparent"
    visible: true

    function layoutCards() {
        let offset = 0;
        for (const card of cards) {
            card.y = offset;
            offset += card.popupHeight + theme.notificationSpacing;
        }
        stackHeight = Math.max(1, offset - (cards.length ? theme.notificationSpacing : 0));
    }

    function removeCard(card) {
        const index = cards.indexOf(card);
        if (index < 0) return;
        cards.splice(index, 1);
        cards = cards.slice();
        card.destroy();
        layoutCards();
    }

    function addNotification(notification) {
        for (const card of cards) {
            if (card.notification.id === notification.id) {
                card.notification = notification;
                card.restartTimeout();
                layoutCards();
                return;
            }
        }

        const card = popupComponent.createObject(stack, {
            notification: notification,
            theme: root.theme,
            width: root.theme.notificationWidth
        });
        if (!card) return;
        card.removeRequested.connect(function() { root.removeCard(card); });
        card.popupHeightChanged.connect(root.layoutCards);
        cards.unshift(card);
        cards = cards.slice();
        while (cards.length > maxVisibleNotifications) {
            const oldest = cards[cards.length - 1];
            oldest.notification.expire();
            removeCard(oldest);
        }
        layoutCards();
        card.enter();
    }

    NotificationServer {
        id: server
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: false
        keepOnReload: false
        onNotification: notification => {
            notification.tracked = true;
            root.addNotification(notification);
        }
    }

    Item {
        id: stack
        anchors.right: parent.right
        width: theme.notificationWidth
        height: parent.height
    }

    Component {
        id: popupComponent
        NotificationCard {
            colors: root.theme.palette
        }
    }
}
