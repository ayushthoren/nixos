import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "components"

ColumnLayout {
    required property Item controller
    readonly property QtObject theme: controller.theme
    readonly property QtObject uiTheme: theme
    readonly property var colors: controller.colors
    readonly property QtObject notification: controller.notification
    property alias imageProbe: imageProbe
    property alias appIcon: appIcon
    property alias replyField: replyField
    id: content
    anchors.fill: parent
    anchors.margins: theme.notificationPadding
    spacing: theme.notificationSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: theme.notificationSpacing

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            visible: controller.hasIcon || controller.avatarImage || !controller.hasImage
            color: controller.accentColor()

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: controller.avatarImage ? 30 : 20
                height: width
                source: controller.avatarImage ? controller.imageSource : controller.iconSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            StyledText {
                theme: uiTheme
                anchors.centerIn: parent
                visible: !controller.hasIcon && !controller.avatarImage
                text: notification.urgency === NotificationUrgency.Critical ? "!" : "•"
                color: colors.activeForeground
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                theme: uiTheme
                Layout.fillWidth: true
                text: controller.hasSummary ? notification.summary : notification.appName
                color: colors.foreground
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            StyledText {
                theme: uiTheme
                Layout.fillWidth: true
                visible: controller.hasSummary && notification.appName !== ""
                text: notification.appName
                color: colors.mutedForeground
                font.pixelSize: theme.fontPixelSize - 1
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }

        Item {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: closeLabel.implicitWidth
            Layout.preferredHeight: closeLabel.implicitHeight

            StyledText {
                theme: uiTheme
                id: closeLabel
                anchors.centerIn: parent
                text: "󰅖"
                color: colors.mutedForeground
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: controller.closeNotification(false)
            }
        }
    }

    StyledText {
        theme: uiTheme
        Layout.fillWidth: true
        visible: controller.hasBody
        text: notification.body
        color: colors.foreground
        wrapMode: Text.Wrap
        maximumLineCount: 8
        elide: Text.ElideRight
        textFormat: Text.RichText
        onLinkActivated: Qt.openUrlExternally(link)
    }

    Image {
        id: imageProbe
        visible: false
        source: controller.imageSource
        asynchronous: true
    }

    Image {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 160 : 0
        visible: controller.hasImage && !controller.avatarImage
        source: controller.imageSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        clip: true
    }

    RowLayout {
        Layout.fillWidth: true
        visible: notification.hasInlineReply
        spacing: theme.notificationSpacing

        Field {
            theme: controller.theme
            id: replyField
            Layout.fillWidth: true
            placeholderText: notification.inlineReplyPlaceholder || "Reply"
            color: colors.foreground
            background: Rectangle { color: colors.overlay; border.color: colors.border }
            onAccepted: controller.sendReply()
        }

        StyledText {
            theme: uiTheme
            text: "Send"
            color: colors.foreground
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: controller.sendReply()
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        visible: notification.actions.length > 0
        spacing: 6

        Repeater {
            model: notification.actions

            Rectangle {
                required property QtObject modelData

                implicitWidth: actionRow.implicitWidth + 12
                implicitHeight: 26
                color: colors.overlay

                Row {
                    id: actionRow
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        implicitSize: 14
                        visible: notification.hasActionIcons
                        source: notification.hasActionIcons ? modelData.identifier : ""
                    }

                    StyledText {
                        theme: uiTheme
                        text: modelData.text
                        color: colors.foreground
                        font.pixelSize: theme.fontPixelSize - 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controller.invokeAction(modelData)
                }
            }
        }
    }

}
