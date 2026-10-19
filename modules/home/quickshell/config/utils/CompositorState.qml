import Quickshell
import Quickshell.Hyprland

Scope {
    id: root
    readonly property bool mango: !!Quickshell.env("MANGO_INSTANCE_SIGNATURE")
    property var monitors: []
    property var tagGroups: []
    property var focusedClient: null
    readonly property var focusedMonitor: monitors.find(monitor => monitor.active) ?? null
    readonly property var focusedTags: tagGroups.find(group => group.monitor === focusedMonitor?.name)?.tags ?? focusedMonitor?.tags ?? []
    readonly property var workspaces: mango ? focusedTags.map(tag => ({
        id: tag.index,
        active: tag.is_active,
        focused: tag.is_active,
        urgent: tag.is_urgent,
        windowCount: tag.client_count
    })) : Hyprland.workspaces
    readonly property bool focusedWorkspaceEmpty: mango
        ? !focusedTags.some(tag => tag.is_active && tag.client_count > 0)
        : (Hyprland.focusedWorkspace?.toplevels?.values.length ?? 0) === 0
    readonly property string focusedTitle: mango
        ? (focusedClient?.is_visible ? focusedClient.title ?? "" : "")
        : Hyprland.activeToplevel?.title ?? ""

    function focusWorkspace(id) {
        if (mango) {
            Quickshell.execDetached(["mmsg", "dispatch", `view,${id},0`]);
        } else {
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
        }
    }

    MangoListener {
        topic: "all-monitors"
        enabled: root.mango
        onUpdated: data => root.monitors = data.monitors ?? []
    }

    MangoListener {
        topic: "all-tags"
        enabled: root.mango
        onUpdated: data => root.tagGroups = data.all_tags ?? []
    }

    MangoListener {
        topic: "focusing-client"
        enabled: root.mango
        onUpdated: data => root.focusedClient = data
    }
}
