import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PopupWindow {
    id: panel
    required property Item anchorItem
    required property QtObject theme
    readonly property var colors: theme.palette
    readonly property string helper: Quickshell.shellPath("utils/display-settings.py")
    property var monitors: []
    property var preferences: ({monitors: {}, night: {enabled: false, temperature: 4000}})
    readonly property var monitor: monitors.find(m => m.name === monitorChoice.value)
        ?? monitors.find(m => m.focused) ?? monitors[0] ?? null
    readonly property string monitorName: monitor?.name ?? ""
    property var previous: null
    property var pending: null
    property string message: ""
    property string commandOutput: ""
    property string operation: ""
    property bool initialized: false
    property bool nightPending: false
    property bool nightBusy: false
    property bool nightTarget: false
    property int sentTemperature: 4000
    property bool sentNightEnabled: false
    property int secondsLeft: 0
    property int temperature: 4000
    property bool nightEnabled: false
    property bool closing: false
    property bool expanded: false
    property bool slideOnClose: true
    readonly property bool busy: operation !== ""
    readonly property bool canEdit: initialized && previous === null && !busy
    readonly property color inputBorder: Qt.alpha(colors.foreground, 0.25)
    readonly property var resolutions: {
        const modes = monitor?.availableModes ?? [];
        const sizes = modes.map(m => m.split("@")[0]);
        const native = sizes.map(s => s.split("x").map(Number))
            .sort((a, b) => b[0] * b[1] - a[0] * a[1])[0];
        if (native) {
            // Keep the native aspect ratio exact, including half and third size.
            const gcd = (a, b) => b ? gcd(b, a % b) : a;
            const divisor = gcd(native[0], native[1]);
            const unit = [native[0] / divisor, native[1] / divisor];
            for (const factor of [1.25, 1.5, 2, 2.5, 3, 4]) {
                const steps = Math.round(divisor / factor);
                const width = unit[0] * steps, height = unit[1] * steps;
                if (width >= 640 && height >= 480) sizes.push(width + "x" + height);
            }
        }
        return [...new Set(sizes)].sort((a, b) => {
            const [aw, ah] = a.split("x").map(Number);
            const [bw, bh] = b.split("x").map(Number);
            return bw * bh - aw * ah;
        });
    }
    readonly property var refreshRates: {
        const resolution = resolutionChoice.value.trim();
        const modes = monitor?.availableModes ?? [];
        const matching = modes.filter(m => !resolution || m.split("@")[0] === resolution);
        return [...new Set((matching.length ? matching : modes)
            .map(m => m.split("@")[1]?.replace(/Hz$/, "") ?? ""))];
    }

    visible: false
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.top: 6
    grabFocus: true
    implicitWidth: Math.min(430, screen ? screen.width : 430)
    implicitHeight: Math.min(content.implicitHeight + 24, screen ? screen.height - theme.barHeight - 24 : 600)
    color: "transparent"
    onVisibleChanged: {
        if (!visible) {
            expanded = false;
            dismissChoices();
            // Losing the grab must discard an unconfirmed preview too.
            if (previous) {
                closing = true;
                if (!busy) revert();
            }
        }
    }

    function refresh() {
        if (!monitorQuery.running) monitorQuery.running = true;
    }
    function loadFields() {
        const prefs = preferences.monitors[monitor?.name] ?? {};
        resolutionChoice.setValue(prefs.resolution ?? "");
        refreshChoice.setValue(prefs.refresh ?? "");
        scaleInput.text = prefs.scale ?? "";
    }
    function toggle() {
        if (visible && expanded) close();
        else open();
    }
    function open() {
        hideTimer.stop();
        slideOnClose = true;
        if (!previous && !busy) message = "";
        refresh();
        if (!initialized && !stateQuery.running) stateQuery.running = true;
        visible = true;
        Qt.callLater(() => { expanded = true; content.forceActiveFocus(); });
    }
    function dismissChoices() {
        monitorChoice.popup.close();
        resolutionChoice.popup.close();
        refreshChoice.popup.close();
    }
    function hide() {
        dismissChoices();
        expanded = false;
        hideTimer.interval = slideOnClose ? theme.notificationSlideDuration : 140;
        hideTimer.restart();
    }
    function close(fade = false) {
        slideOnClose = !fade;
        closing = previous !== null;
        hide();
        if (previous && !busy) revert();
    }
    function run(command, kind) {
        if (busy || action.running) return;
        if (kind !== "revert") message = "";
        commandOutput = "";
        operation = kind;
        action.command = command;
        action.running = true;
    }
    function finishAction(code, output) {
        const kind = operation;
        const failed = code !== 0 || /error|invalid|failed/i.test(output);
        operation = "";
        if (failed) message = output || "Command failed (" + code + ")";
        if (kind === "save" && !failed) {
            const updated = Object.assign({}, preferences.monitors);
            updated[previous.name] = pending;
            preferences = {monitors: updated, night: preferences.night};
            previous = null;
            pending = null;
            closing = false;
            loadFields();
            refresh();
        } else if (kind === "revert") {
            closing = false;
            if (!failed) {
                previous = null;
                pending = null;
                secondsLeft = 0;
                loadFields();
                refresh();
            } else {
                // Keep the snapshot so Revert can be retried after an error.
                if (!visible || !expanded) open();
            }
        } else if (kind === "preview") {
            if (failed || closing) {
                revert();
            } else {
                secondsLeft = 15;
                refresh();
            }
        } else if (closing && previous) {
            revert();
        }
    }
    function monitorCommand(m, mode, scale) {
        return ["hyprctl", "eval", "hl.monitor({ output = " + JSON.stringify(m.name)
            + ", mode = " + JSON.stringify(mode) + ", scale = " + JSON.stringify(String(scale)) + " })"];
    }
    function apply() {
        if (!monitor || previous || busy || !initialized || monitorQuery.running) return;
        const resolution = resolutionChoice.value.trim();
        const refresh = refreshChoice.value.trim();
        const scaleText = scaleInput.text.trim();
        const scale = scaleText.toLowerCase() === "auto" ? "" : scaleText;
        if (resolution && !/^[1-9]\d*x[1-9]\d*$/.test(resolution)) {
            message = "Enter a resolution such as 1920x1200."; return;
        }
        if (refresh && (!/^\d+(\.\d+)?$/.test(refresh) || Number(refresh) <= 0)) {
            message = "Enter a positive refresh rate."; return;
        }
        if (scale && (!/^\d+(\.\d+)?$/.test(scale) || Number(scale) <= 0)) {
            message = "Enter a positive scale."; return;
        }
        previous = {name: monitor.name, width: monitor.width, height: monitor.height,
            refreshRate: monitor.refreshRate, scale: monitor.scale};
        pending = {resolution: resolution, refresh: refresh, scale: scale};
        secondsLeft = 15;
        run(["python3", helper, "preview", monitor.name, JSON.stringify(pending)], "preview");
    }
    function keep() {
        if (!previous || busy || closing) return;
        run(["python3", helper, "monitor", previous.name, JSON.stringify(pending)], "save");
    }
    function revert() {
        if (!previous || busy) return;
        run(monitorCommand(previous, previous.width + "x" + previous.height + "@" + previous.refreshRate, previous.scale), "revert");
    }
    function setNight(enabled) {
        temperatureTimer.stop();
        nightTarget = enabled;
        nightPending = true;
        flushNight();
    }
    function flushNight() {
        if (nightBusy || nightAction.running || !nightPending || !initialized) return;
        nightPending = false;
        nightBusy = true;
        sentTemperature = temperature;
        sentNightEnabled = nightTarget;
        nightAction.command = sentNightEnabled === nightEnabled
            ? ["python3", helper, "temperature", String(sentTemperature)]
            : ["python3", helper, "night", String(sentNightEnabled), String(sentTemperature)];
        nightAction.running = true;
    }
    function saveTemperature() {
        // A temperature change preserves the last requested On/Off state.
        nightPending = true;
        flushNight();
    }

    onMonitorNameChanged: if (!previous && !busy) Qt.callLater(loadFields)
    Shortcut { sequence: "Escape"; enabled: panel.visible; onActivated: panel.close(true) }
    Shortcut { sequence: "F8"; enabled: panel.visible; onActivated: panel.close() }
    Timer { id: hideTimer; interval: theme.notificationSlideDuration; onTriggered: panel.visible = false }
    Timer {
        id: temperatureTimer
        interval: 150
        onTriggered: panel.saveTemperature()
    }
    Process {
        id: stateQuery
        command: ["python3", panel.helper, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    panel.preferences = JSON.parse(text);
                    panel.temperature = panel.preferences.night.temperature;
                    panel.nightEnabled = panel.preferences.night.enabled;
                    panel.nightTarget = panel.nightEnabled;
                    panel.initialized = true;
                    if (!panel.previous && !panel.busy) panel.loadFields();
                } catch (e) { panel.message = "Could not read display preferences: " + e; }
            }
        }
    }
    Process {
        id: monitorQuery
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    panel.monitors = JSON.parse(text);
                    if (monitorChoice.value && !panel.monitors.some(m => m.name === monitorChoice.value))
                        monitorChoice.setValue("");
                } catch (e) { panel.message = "Could not read monitors: " + e; }
            }
        }
    }
    Process {
        id: action
        stdout: StdioCollector { onStreamFinished: panel.commandOutput += text }
        stderr: StdioCollector { onStreamFinished: panel.commandOutput += text }
        onExited: (code, status) => {
            const output = panel.commandOutput.trim();
            // Process.running may still be true inside onExited. Start follow-up
            // commands on the next event-loop turn, after it has settled.
            Qt.callLater(() => panel.finishAction(code, output));
        }
    }
    Process {
        id: nightAction
        property string output: ""
        onStarted: output = ""
        stdout: StdioCollector { onStreamFinished: nightAction.output += text }
        stderr: StdioCollector { onStreamFinished: nightAction.output += text }
        onExited: (code, status) => {
            const output = nightAction.output.trim();
            const temperature = panel.sentTemperature;
            const enabled = panel.sentNightEnabled;
            Qt.callLater(() => {
                panel.nightBusy = false;
                if (code !== 0 || /error|invalid|failed/i.test(output)) {
                    panel.message = output || "Could not update night light.";
                    if (!panel.nightPending) panel.nightTarget = panel.nightEnabled;
                } else {
                    panel.nightEnabled = enabled;
                    panel.preferences = {monitors: panel.preferences.monitors,
                        night: {enabled: enabled, temperature: temperature}};
                }
                panel.flushNight();
            });
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: panel.previous !== null && !panel.busy && !panel.closing && panel.secondsLeft > 0
        onTriggered: if (--panel.secondsLeft <= 0) panel.revert()
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (panel.visible && ["monitoradded", "monitorremoved", "configreloaded"].includes(event.name)) panel.refresh();
        }
    }

    component LabelText: Text {
        color: panel.colors.foreground
        font.family: panel.theme.fontFamily
        font.pixelSize: panel.theme.fontPixelSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    component ActionButton: Button {
        id: button
        implicitHeight: 30
        HoverHandler { cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
        leftPadding: 10; rightPadding: 10
        font.family: panel.theme.fontFamily
        font.pixelSize: panel.theme.fontPixelSize
        background: Rectangle {
            color: button.hovered || button.down || button.checked ? panel.colors.activeSurface : panel.colors.overlay
            opacity: button.enabled ? 1 : 0.4
        }
        contentItem: Text {
            text: button.text
            font: button.font
            color: button.hovered || button.down || button.checked ? panel.colors.activeForeground : panel.colors.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: button.enabled ? 1 : 0.4
        }
    }
    component Field: TextField {
        implicitHeight: 34
        font.family: panel.theme.fontFamily
        font.pixelSize: panel.theme.fontPixelSize
        color: panel.colors.foreground
        placeholderText: "Auto"
        placeholderTextColor: panel.colors.mutedForeground
        selectionColor: panel.colors.activeSurface
        selectedTextColor: panel.colors.activeForeground
        selectByMouse: true
        padding: 8
        background: Rectangle {
            color: panel.colors.overlay
            border.width: 1
            border.color: parent.activeFocus ? panel.colors.foreground : panel.inputBorder
        }
    }
    component Choice: ComboBox {
        id: choice
        property string hint: "Auto"
        property string value: ""
        property var options: []
        model: ["Auto", ...options]
        function setValue(next) {
            value = next;
            syncText();
        }
        function syncText() {
            currentIndex = model.indexOf(value || "Auto");
            editText = value || "Auto";
        }
        onActivated: index => setValue(index === 0 ? "" : model[index])
        editable: true
        implicitHeight: 34
        font.family: panel.theme.fontFamily
        font.pixelSize: panel.theme.fontPixelSize
        leftPadding: 8; rightPadding: 28
        contentItem: TextField {
            text: choice.editText
            onTextEdited: {
                choice.editText = text;
                choice.value = text.trim().toLowerCase() === "auto" ? "" : text;
            }
            font: choice.font
            color: panel.colors.foreground
            placeholderText: choice.hint
            placeholderTextColor: panel.colors.mutedForeground
            selectionColor: panel.colors.activeSurface
            selectedTextColor: panel.colors.activeForeground
            selectByMouse: true
            padding: 0
            readOnly: !choice.editable
            background: null
        }
        indicator: Text {
            x: choice.width - width - 8
            anchors.verticalCenter: parent.verticalCenter
            text: "v"
            font: choice.font
            color: panel.colors.foreground
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
        HoverHandler { cursorShape: choice.editable ? Qt.IBeamCursor : Qt.PointingHandCursor }
        background: Rectangle {
            color: panel.colors.overlay
            border.width: 1
            border.color: choice.activeFocus ? panel.colors.foreground : panel.inputBorder
        }
        delegate: ItemDelegate {
            id: entry
            required property var modelData
            required property int index
            width: choice.width
            height: 32
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            highlighted: choice.highlightedIndex === index
            contentItem: Text {
                text: entry.modelData
                color: entry.highlighted ? panel.colors.activeForeground : panel.colors.foreground
                font: choice.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle { color: entry.highlighted ? panel.colors.activeSurface : panel.colors.surface }
        }
        popup: Popup {
            popupType: Popup.Item
            x: 0
            y: choice.height
            margins: 0
            width: choice.width
            padding: 1
            // Keep the list below its field; scroll instead of flipping it upward.
            implicitHeight: Math.min(220, list.contentHeight + 2,
                Math.max(0, panel.height - choice.mapToItem(panel.contentItem, 0, choice.height).y - 12))
            background: Rectangle { color: panel.colors.surface; border.color: panel.inputBorder }
            contentItem: ListView {
                id: list
                clip: true
                implicitHeight: contentHeight
                model: choice.popup.visible ? choice.delegateModel : null
                currentIndex: choice.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator {}
            }
        }
        onModelChanged: Qt.callLater(syncText)
        Component.onCompleted: syncText()
    }

    Rectangle {
        width: parent.width
        height: parent.height
        y: panel.expanded || !panel.slideOnClose ? 0 : -height - 8
        clip: true
        color: panel.colors.surface
        border.width: 1
        border.color: panel.colors.border
        opacity: panel.expanded ? 1 : 0
        Behavior on y { NumberAnimation { duration: theme.notificationSlideDuration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        Flickable {
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: content.implicitHeight
            clip: true
            ColumnLayout {
                id: content
                width: parent.width
                spacing: 10
                focus: true
                RowLayout {
                    LabelText { text: "Display"; font.bold: true }
                    Text {
                        text: "󰅖"
                        color: closeHover.hovered ? panel.colors.critical : panel.colors.mutedForeground
                        font.family: panel.theme.fontFamily
                        font.pixelSize: panel.theme.fontPixelSize + 2
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        HoverHandler { id: closeHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.close()
                        }
                    }
                }
                RowLayout {
                    LabelText { text: "Night light" }
                    ActionButton {
                        text: panel.nightTarget ? "On" : "Off"
                        checked: panel.nightTarget
                        enabled: panel.initialized
                        onClicked: panel.setNight(!panel.nightTarget)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Slider {
                        id: warmth
                        HoverHandler { cursorShape: warmth.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
                        Layout.fillWidth: true
                        implicitHeight: 20
                        enabled: panel.initialized
                        from: 1000; to: 6500; stepSize: 100
                        value: panel.temperature
                        onMoved: {
                            panel.temperature = Math.round(value);
                            if (!pressed) temperatureTimer.restart();
                        }
                        onPressedChanged: if (!pressed && enabled) temperatureTimer.restart()
                        background: Rectangle {
                            x: warmth.leftPadding
                            y: warmth.topPadding + warmth.availableHeight / 2 - height / 2
                            width: warmth.availableWidth; height: 3
                            color: panel.colors.border
                            Rectangle { width: warmth.visualPosition * parent.width; height: parent.height; color: panel.colors.foreground }
                        }
                        handle: Rectangle {
                            x: warmth.leftPadding + warmth.visualPosition * (warmth.availableWidth - width)
                            y: warmth.topPadding + warmth.availableHeight / 2 - height / 2
                            width: 10; height: 14
                            color: panel.colors.foreground
                        }
                    }
                    LabelText {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 64
                        horizontalAlignment: Text.AlignRight
                        text: panel.temperature + " K"
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: panel.colors.border }
                Choice {
                    id: monitorChoice
                    Layout.fillWidth: true
                    editable: false
                    enabled: panel.canEdit
                    options: panel.monitors.map(m => m.name)
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        LabelText { text: "Resolution"; color: panel.colors.mutedForeground }
                        Choice {
                            id: resolutionChoice
                            Layout.fillWidth: true
                            enabled: panel.canEdit
                            options: panel.resolutions
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        LabelText { text: "Refresh Rate"; color: panel.colors.mutedForeground }
                        Choice {
                            id: refreshChoice
                            Layout.fillWidth: true
                            enabled: panel.canEdit
                            options: panel.refreshRates
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    LabelText { text: "Scale"; color: panel.colors.mutedForeground }
                    Field {
                        id: scaleInput
                        Layout.fillWidth: true
                        enabled: panel.canEdit
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        visible: !panel.previous
                        text: "Apply"
                        enabled: !!panel.monitor && panel.initialized && !monitorQuery.running && !panel.busy
                        onClicked: panel.apply()
                    }
                    ActionButton {
                        visible: !!panel.previous
                        enabled: !panel.busy
                        text: "Revert"
                        onClicked: panel.revert()
                    }
                    ActionButton {
                        visible: !!panel.previous
                        enabled: !panel.busy
                        text: "Keep (" + panel.secondsLeft + ")"
                        onClicked: panel.keep()
                    }
                }
                LabelText { visible: text !== ""; text: panel.message; color: panel.colors.critical }
            }
        }
    }
}
