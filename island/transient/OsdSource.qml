import QtQuick
import qs.core
import qs.services

// Feeds this screen's island with the OSD transient (osd.*):
//  - volume / mic: on the focused monitor
//  - brightness: on the monitor that changed (with "Sync brightness" every monitor reports its own)
// Startup / wake reads aren't changes: nothing shows for a moment after creation, nor before
// SuspendManager.wakeReady. Nor while this screen's island has the dashboard open (its sliders
// already show the level). The volume one is skipped while the volume Iwidget shows in the
// island's current mode (osd.skipWithVolumeWidget: placed in a section and not hidden in compact /
// expanded, whichever the island is in); an OSD already up keeps updating. With osd.volumeWidget the
// volume shows as its Iwidget instead (Island.volumeFlash), when one is in the layout.
Item {
    id: root

    required property string screenName

    property bool armed: false
    Timer {
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }

    readonly property bool volumeWidgetShown: {
        // any volume Iwidget (there may be several) on the island and shown in this mode
        const mode = Runtime.isIslandExpanded(screenName) ? "expanded" : "compact";
        return (Store.island.widgets ?? []).some(w => w.id === "volume" && w.section !== "off" && w[mode] !== "hidden");
    }
    readonly property bool osdUp: Runtime.transientOn(screenName)?.kind === "osd"
    // a volume Iwidget in the layout (hidden in both modes or not), for osd.volumeWidget
    readonly property bool volumeWidgetPlaced: (Store.island.widgets ?? []).some(w => w.id === "volume" && w.section !== "off")

    function show(type: string, value: real, muted: bool) {
        if (!armed || !Store.osd.enabled || !SuspendManager.wakeReady)
            return;
        if (Runtime.activeApp === "dashboard" && Runtime.activeScreen === screenName)
            return;
        Runtime.showTransient(screenName, "osd", {
            type: type,
            value: value,
            muted: muted
        }, Store.osd.duration > 0 ? Store.osd.duration : 1500);
    }

    Connections {
        target: Audio
        function onVolumeChanged(volume, muted, node) {
            if (Hypr.focusedScreen !== root.screenName)
                return;
            // as its widget (osd.volumeWidget): the island shows the volume Iwidget for a moment; an app
            // open over the island (the widget isn't there) or no volume widget placed → the slider
            const appHere = Runtime.activeApp !== "" && Runtime.activeScreen === root.screenName;
            if (Store.osd.volumeWidget && root.volumeWidgetPlaced && !appHere && !root.osdUp) {
                if (root.armed && Store.osd.enabled && SuspendManager.wakeReady)
                    Runtime.flashVolume(root.screenName);
                return;
            }
            if (root.osdUp || !(Store.osd.skipWithVolumeWidget && root.volumeWidgetShown))
                root.show("volume", volume, muted);
        }
        function onMicVolumeChanged(volume, muted, node) {
            if (Hypr.focusedScreen === root.screenName)
                root.show("mic", volume, muted);
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged(value, screen) {
            if (screen?.name === root.screenName)
                root.show("brightness", value, false);
        }
    }
}
