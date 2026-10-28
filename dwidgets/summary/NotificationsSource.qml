import QtQuick
import Quickshell
import qs.core
import qs.services

// The Notifications summary's data (2026-10-17): this session's notifications, newest first (the
// bell Iwidget's count). A click runs the notification's default action, else opens the app on it.
QtObject {
    id: root

    readonly property string title: "Notifications"
    readonly property string icon: Notifications.silent ? "notifications_paused" : "notifications"
    readonly property string empty: "No notifications"
    readonly property string action: ""

    readonly property int count: Notifications.sessionList.length
    readonly property string countText: count > 0 ? `${count} new` : "None"
    // refreshed each minute (the ages)
    property real now: Date.now()
    readonly property Timer clock: Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }
    readonly property var items: {
        void now;
        return Notifications.sessionList.slice().reverse().map(e => ({
                    key: e.id,
                    lead: "notifications",
                    image: iconOf(e),
                    title: e.summary || e.appName,
                    sub: e.summary ? (e.body || e.appName) : "",
                    time: Notifications.age(e.time),
                    entry: e
                }));
    }

    // a picture, the app's icon, else "" (the bell)
    function iconOf(e: var): string {
        const i = e?.appIcon ?? "";
        if (i.startsWith("material:"))
            return "";
        if (i.startsWith("/"))
            return "file://" + i;
        if (i.startsWith("file:") || i.startsWith("data:") || i.startsWith("image:"))
            return i;
        return Quickshell.iconPath(i || (e?.appName ?? "").toLowerCase(), true);
    }

    function opened() {
        now = Date.now();
    }
    function openApp() {
        Runtime.openApp("notifications", {});
    }
    function activate(item: var) {
        const e = item.entry;
        if (e.hasDefault) {
            Runtime.closeApp();
            Notifications.invokeAction(e.id, "default");
        } else
            Runtime.openApp("notifications", {
                id: e.id
            });
    }
    function run() {
    }
}
