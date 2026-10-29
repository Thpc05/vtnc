import QtQuick
import Quickshell.Services.Notifications
import qs.core

// One notification in Notifications.list (2026-10-15, vtnc's own). While the app's notification is alive
// everything is read from it (an app replacing it updates it in place); one from the saved history has
// only `stored` (its text and app, no image or actions: those live with the app's notification).
QtObject {
    id: root

    required property int id
    property Notification notification: null
    // the saved fields of a history entry (one from before this shell started: `fromHistory`)
    property var stored: ({})
    property bool fromHistory: false
    property real time: Date.now()
    // showing on the island now (until its timeout, a dismiss or an action)
    property bool popup: false

    readonly property string appName: notification ? notification.appName : (stored.appName ?? "")
    readonly property string appIcon: notification ? notification.appIcon : (stored.appIcon ?? "")
    readonly property string image: notification?.image ?? ""
    readonly property string summary: notification ? notification.summary : (stored.summary ?? "")
    readonly property string body: Notifications.cleanBody(notification ? notification.body : (stored.body ?? ""), appName)
    // 0 low, 1 normal, 2 critical (NotificationUrgency's values; the history keeps the names)
    readonly property int urgency: {
        if (notification)
            return notification.urgency;
        const i = Math.max(["low", "normal", "critical"].indexOf(stored.urgency), ["0", "1", "2"].indexOf(String(stored.urgency)));
        return i < 0 ? 1 : i;
    }
    readonly property bool critical: urgency === NotificationUrgency.Critical

    // the buttons: the app's actions with a label; "default" is no button, it's a click on the card
    readonly property var actions: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "").map(a => ({
                identifier: a.identifier,
                text: a.text
            }))
    readonly property bool hasDefault: (notification?.actions ?? []).some(a => a.identifier === "default")

    // how long it pops up (ms): the app's own timeout (Quickshell gives it in seconds) when it gave one and
    // island.notifications.useAppTimeout is on, else island.notifications.duration (2026-10-27, user; 5 s by
    // default); a critical one without its own stays until it's dismissed
    readonly property int timeout: {
        const t = notification?.expireTimeout ?? -1;
        const own = Store.island.notifications?.useAppTimeout ?? true;
        if (own && t > 0)
            return Math.round(t * 1000);
        if (critical)
            return 0;
        return Math.max(1, Store.island.notifications?.duration || 5) * 1000;
    }

    property Timer timer: Timer {
        interval: root.timeout
        running: root.popup && interval > 0 && !Notifications.timersPaused
        onTriggered: root.popup = false
    }

    // what the history file keeps (icons only by name or path)
    function toJson() {
        return {
            appName: appName,
            appIcon: /^(data|image):/.test(appIcon) ? "" : appIcon,
            summary: summary,
            body: body,
            urgency: ["low", "normal", "critical"][urgency] ?? "normal",
            time: time
        };
    }
}
