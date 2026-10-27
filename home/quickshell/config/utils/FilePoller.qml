import QtQuick

import Quickshell
import Quickshell.Io

// Sysfs does not reliably emit change notifications; keep timed reads, without
// launching a shell and cat for each sample.
Scope {
    id: root
    required property string path
    property int interval: 5000
    property string value: ""

    FileView {
        id: file
        path: root.path
        preload: true
        blockLoading: false
        printErrors: false
        onLoaded: root.value = text().trim()
        onLoadFailed: root.value = ""
    }
    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: file.reload()
    }
}
