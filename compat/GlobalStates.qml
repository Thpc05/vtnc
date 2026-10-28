pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Compat GlobalStates: only the state the compat-based code reads.
// Open/close state is derived from vtnc's Runtime (apps system).
Singleton {
    id: root

    readonly property bool dashboardOpen: Runtime.activeApp === "dashboard"
    readonly property bool launcherOpen: Runtime.activeApp === "launcher"
    readonly property bool overviewOpen: false
    readonly property bool settingsWindowVisible: Runtime.activeApp === "settings"

    // vtnc's dashboard only has the Widgets tab
    property int dashboardCurrentTab: 0
    property int widgetsTabCurrentIndex: 0

    property string launcherSearchText: ""
    function clearLauncherState() {
        launcherSearchText = "";
    }

    // FullPlayer falls back to the wallpaper when the track has no art
    readonly property QtObject wallpaperManager: QtObject {
        readonly property string currentWallpaper: Store.wallpaper.current
        function getLockscreenFramePath(path) {
            return path;
        }
    }
}
