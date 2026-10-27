import QtQuick

import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property list<string> command
    property int interval: 1000
    property string value: ""

    Process {
        id: proc
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: root.value = this.text.trim()
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }
}
