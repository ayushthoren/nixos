import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

Item {
    required property QtObject controller
    readonly property QtObject uiTheme: controller.theme
    id: content
    anchors.fill: parent
    opacity: controller.contentVisible ? 1 : 0
    y: controller.contentVisible ? 0 : -14

    Behavior on opacity {
        NumberAnimation {
            duration: controller.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: controller.animationDuration
            easing.type: Easing.InOutCubic
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(360, parent.width - 40)
        spacing: 0

        StyledText {
            theme: uiTheme
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: controller.colors.foreground
            font.pixelSize: 48
            font.bold: true
        }
        StyledText {
            theme: uiTheme
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
            color: controller.colors.mutedForeground
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.topMargin: 30
            clip: true
            color: controller.colors.surface
            border.width: 1
            border.color: passwordInput.activeFocus
                ? controller.colors.activeSurface : controller.colors.border

            StyledText {
                theme: uiTheme
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: passwordInput.text.length === 0
                text: "Password"
                color: controller.colors.mutedForeground
            }
            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: controller.colors.foreground
                selectionColor: controller.colors.activeSurface
                selectedTextColor: controller.colors.activeForeground
                font.family: controller.theme.fontFamily
                font.pixelSize: controller.theme.fontPixelSize * 1.5
                echoMode: TextInput.Password
                passwordCharacter: "•"
                enabled: !controller.authenticating
                focus: true
                onAccepted: controller.authenticate(text)
                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: controller
                    function onResetInput() {
                        passwordInput.clear();
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
        StyledText {
            theme: uiTheme
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            text: controller.identity
            color: controller.colors.mutedForeground
        }
        StyledText {
            theme: uiTheme
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.preferredHeight: 18
            opacity: controller.authenticating || controller.statusMessage !== "" ? 1 : 0
            text: controller.authenticating ? "Authenticating…" : controller.statusMessage
            color: controller.statusMessage !== ""
                ? controller.colors.critical : controller.colors.mutedForeground
            font.pixelSize: controller.theme.fontPixelSize - 1
        }
    }
}
