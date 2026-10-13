import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool enabled: true
    property var sinkId: null
    property string value: ""
    property bool refreshPending: false

    function refresh(): void {
        if (!enabled) return;
        if (readVolume.running) refreshPending = true;
        else readVolume.running = true;
    }

    onSinkIdChanged: refresh()
    onEnabledChanged: {
        monitor.running = enabled;
        if (enabled) refresh();
        else {
            updates.stop();
            reconnect.stop();
        }
    }
    Component.onCompleted: refresh()

    Process {
        id: monitor
        command: [ "pw-mon", "--no-colors", "--hide-props" ]
        running: root.enabled
        stdout: SplitParser {
            onRead: data => {
                // Ignore client events, including those caused by our own wpctl reads.
                if (/Param:Props:(volume|channelVolumes|mute)\b/.test(data))
                    updates.restart();
            }
        }
        onExited: {
            if (root.enabled) {
                root.value = "";
                reconnect.restart();
            }
        }
    }

    // Retry only after the listener disconnects (for example, an audio service restart).
    Timer {
        id: reconnect
        interval: 2000
        onTriggered: {
            monitor.running = true;
            root.refresh();
        }
    }

    // Coalesce the volume and mute parameters from the same event.
    Timer {
        id: updates
        interval: 50
        onTriggered: root.refresh()
    }

    Process {
        id: readVolume
        command: [ "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@" ]
        stdout: StdioCollector {
            onStreamFinished: root.value = this.text.trim()
        }
        onExited: {
            if (root.refreshPending) {
                root.refreshPending = false;
                root.refresh();
            }
        }
    }
}
