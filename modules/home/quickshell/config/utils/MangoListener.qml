import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    required property string topic
    property bool enabled: false
    signal updated(var data)

    Process {
        id: process
        command: ["mmsg", "watch", root.topic]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.updated(JSON.parse(data));
                } catch (error) {
                    console.warn("Invalid Mango IPC message:", error);
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!process.running) process.running = true;
        }
    }

    onEnabledChanged: {
        if (!enabled) process.running = false;
    }
}
