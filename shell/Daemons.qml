import QtQuick
import Quickshell
import qs.base.services
import qs.island.transient as Transient

// What must run even when nothing on screen uses it: the island's notification takeover, the battery
// warnings, and the services whose watchers have to be alive before the first widget asks for them.
Scope {
    // when notification popups take over the island (the notification transient)
    Transient.NotificationPresenter {}
    BatteryWarnings {}

    Component.onCompleted: {
        Notifications.list;
        NetworkService.wifiEnabled;
        Wallpapers.current;
        Controls.gameMode;
        // its watchers store every copy in cliphist
        Clipboard.entries;
        // cava for the dashboard's visualizers while music plays, so an open doesn't wait for it
        VisualizerKeeper.held;
    }
}
