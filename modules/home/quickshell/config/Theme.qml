import QtQuick
import Quickshell

import "utils"

QtObject {
    readonly property QtObject fallbackWallust: QtObject {
        readonly property color foreground: "#EEEEEE"
        readonly property color background: "#121212"
        readonly property color color1: "#121212"
        readonly property color color7: "#DEDEDE"
    }
    readonly property CommandPoller wallustWatcher: CommandPoller {
        command: [ "sh", "-c", "stat -c %Y ~/.cache/wallust/ColorsQuickshell.qml 2>/dev/null || echo 0" ]
        interval: 2000
    }
    readonly property string wallustRevision: wallustWatcher.value || "startup"
    readonly property url wallustSource: `file://${Quickshell.env("HOME")}/.cache/wallust/ColorsQuickshell.qml?rev=${wallustRevision}`
    readonly property Loader wallustLoader: Loader {
        source: wallustSource
    }
    readonly property var wallust: wallustLoader.item || fallbackWallust

    readonly property string fontFamily: "GoMono Nerd Font"
    readonly property int fontPixelSize: 14

    readonly property int popupGap: 6
    readonly property int popupPadding: 12
    readonly property int surfaceRadius: 0
    readonly property int fadeDuration: 140

    readonly property int barHeight: 25
    readonly property int pillHorizontalPadding: 22
    readonly property int workspaceHorizontalPadding: 14
    readonly property int pillSpacing: 7
    readonly property int notificationWidth: 360
    readonly property int notificationMargin: 14
    readonly property int notificationPadding: 14
    readonly property int notificationSpacing: 10
    readonly property int notificationRadius: 0
    readonly property int notificationSlideDistance: 48
    readonly property int notificationSlideDuration: 230

    readonly property var palette: ({
        background: wallust.background,
        foreground: wallust.foreground,
        surface: Qt.darker(wallust.background, 1.5),
        activeSurface: wallust.color7,
        activeForeground: wallust.color1,
        overlay: Qt.rgba(0, 0, 0, 0.18),
        inputBorder: Qt.alpha(wallust.foreground, 0.25),
        border: Qt.lighter(Qt.darker(wallust.background, 1.5), 1.18),
        mutedForeground: Qt.rgba(wallust.foreground.r, wallust.foreground.g, wallust.foreground.b, 0.72),
        critical: "#D65D5D",
        low: "#6E8F62"
    })
}
