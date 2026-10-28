pragma Singleton

import QtQuick
import Quickshell
import qs.apps.session as Session
import qs.apps.tools as Tools
import qs.apps.launcher as Launcher
import qs.apps.wallpaper as Wallpaper
import qs.apps.dashboard as Dashboard
import qs.apps.settings as Settings
import qs.apps.notifications as NotificationsApp
import qs.apps.clipboard as ClipboardApp
import qs.apps.notes as NotesApp
import qs.apps.dino as DinoApp
import qs.apps.helper as HelperApp

// Island apps. To add one: create apps/<id>/App.qml (an VtncApp) + View.qml,
// import it here and add it to `apps`. Open it with `qs -c vtnc ipc call <id> open` (add an AppTarget in core/Ipc.qml).
Singleton {
    id: root

    readonly property list<QtObject> apps: [
        Session.App {},
        Tools.App {},
        Launcher.App {},
        Wallpaper.App {},
        Dashboard.App {},
        Settings.App {},
        NotificationsApp.App {},
        ClipboardApp.App {},
        NotesApp.App {},
        DinoApp.App {},
        HelperApp.App {}
    ]

    function get(appId: string): QtObject {
        return apps.find(a => a.appId === appId) ?? null;
    }

    function has(appId: string): bool {
        return get(appId) !== null;
    }
}
