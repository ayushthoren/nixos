import QtQuick
import QtQuick.Controls

ComboBox {
    required property QtObject theme
    readonly property var colors: theme.palette
    required property Item viewport
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
    font.family: theme.fontFamily
    font.pixelSize: theme.fontPixelSize
    leftPadding: 8; rightPadding: 28
    contentItem: TextField {
        text: choice.editText
        onTextEdited: {
            choice.editText = text;
            choice.value = text.trim().toLowerCase() === "auto" ? "" : text;
        }
        font: choice.font
        color: colors.foreground
        placeholderText: choice.hint
        placeholderTextColor: colors.mutedForeground
        selectionColor: colors.activeSurface
        selectedTextColor: colors.activeForeground
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
        color: colors.foreground
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    HoverHandler { cursorShape: choice.editable ? Qt.IBeamCursor : Qt.PointingHandCursor }
    background: Rectangle {
        color: colors.overlay
        border.width: 1
        border.color: choice.activeFocus ? colors.foreground : theme.palette.inputBorder
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
            color: entry.highlighted ? colors.activeForeground : colors.foreground
            font: choice.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle { color: entry.highlighted ? colors.activeSurface : colors.surface }
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
            Math.max(0, viewport.height - choice.mapToItem(viewport, 0, choice.height).y - theme.popupPadding))
        background: Rectangle { color: colors.surface; border.color: theme.palette.inputBorder }
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
