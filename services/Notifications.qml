pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core

// Notifications (2026-10-15, vtnc's own; replaces ambxst's service): the D-Bus server and the list.
//  - list: every notification, oldest first (NotificationEntry); the last `keep` are saved to
//    ~/.cache/vtnc/notifications.json (text only) and come back after a restart. Settings → Apps →
//    Notifications (2026-10-17): `keep` is the history size, `persist` off = nothing saved (the file
//    emptied), `maxAgeDays` drops older ones (on load and once an hour; 0 = never)
//  - popupList: the ones popping up now; each for its timeout (NotificationEntry.timeout). The island
//    shows them (island/transient/NotificationPresenter + NotificationView), which pauses the timers
//    while they wait or are hovered
//  - silent (do not disturb): nothing pops up, they still go to the list
// An app closing its notification takes it out; an action or the card's click (its "default" action)
// runs it in the app and takes it out (always, even when the app asks to keep it: resident).
Singleton {
    id: root

    property bool silent: false
    property var list: []
    readonly property var popupList: list.filter(n => n.popup)
    // the ones received since the shell started (the bell counts these, not the saved history; user)
    readonly property var sessionList: list.filter(n => !n.fromHistory)
    property bool timersPaused: false

    readonly property var cfg: Store.appOptions.notifications
    readonly property int keep: Math.max(10, cfg?.historySize || 100)
    readonly property bool persist: cfg?.persist ?? true
    readonly property int maxAgeDays: cfg?.maxAgeDays ?? 0
    // a smaller size or a shorter age applies right away
    onKeepChanged: if (historyLoaded) {
        list = trimmed(list);
        save();
    }
    onMaxAgeDaysChanged: dropOld()
    onPersistChanged: save()

    // the ones older than maxAgeDays go (never one popping up)
    function dropOld() {
        if (maxAgeDays <= 0 || !historyLoaded)
            return;
        const limit = Date.now() - maxAgeDays * 86400000;
        const old = list.filter(e => !e.popup && e.time < limit);
        if (old.length === 0)
            return;
        list = list.filter(e => !old.includes(e));
        for (const e of old) {
            e.notification?.dismiss();
            e.destroy(1000);
        }
        save();
    }
    Timer {
        interval: 3600000
        running: root.maxAgeDays > 0
        repeat: true
        onTriggered: root.dropOld()
    }
    property int nextId: 1
    property bool historyLoaded: false

    NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: false

        onNotification: n => {
            if (!n.summary && !n.body)
                return;
            n.tracked = true;
            const entry = entryComponent.createObject(root, {
                id: root.nextId++,
                notification: n,
                popup: !root.silent
            });
            n.closed.connect(reason => {
                if (reason === NotificationCloseReason.CloseRequested)
                    root.remove(entry, false);
            });
            root.list = root.trimmed([...root.list, entry]);
            root.save();
        }
    }

    Component {
        id: entryComponent
        NotificationEntry {}
    }

    // the oldest past `keep` go (never one popping up)
    function trimmed(l) {
        let extra = l.length - keep;
        if (extra <= 0)
            return l;
        return l.filter(e => {
            if (extra > 0 && !e.popup) {
                extra--;
                e.notification?.dismiss();
                e.destroy(1000);
                return false;
            }
            return true;
        });
    }

    // takes it out of the list; `dismiss` closes the app's notification too
    function remove(entry, dismiss) {
        if (!entry || !list.includes(entry))
            return;
        list = list.filter(e => e !== entry);
        if (dismiss)
            entry.notification?.dismiss();
        // later: the card may still be leaving with it
        entry.destroy(1000);
        save();
    }

    function discardNotification(id) {
        remove(list.find(e => e.id === id), true);
    }

    function discardAllNotifications() {
        const all = list;
        list = [];
        for (const e of all) {
            e.notification?.dismiss();
            e.destroy(1000);
        }
        save();
    }

    // an action (or "default", the card's click): the app runs it and the notification goes
    function invokeAction(id, identifier) {
        const entry = list.find(e => e.id === id);
        const n = entry?.notification;
        const action = n?.actions.find(a => a.identifier === identifier);
        if (!action)
            return;
        const resident = n.resident;
        // out of the list first: invoking closes the app's notification (a resident one we close after)
        remove(entry, false);
        action.invoke();
        if (resident)
            n.dismiss();
    }

    function pauseAllTimers() {
        timersPaused = true;
    }
    function resumeAllTimers() {
        timersPaused = false;
    }
    function hideAllPopups() {
        for (const e of popupList)
            e.popup = false;
    }

    // the body as text: no markup, and Chromium browsers' first line (the site's link) dropped
    function cleanBody(body, appName) {
        let b = body ?? "";
        if (/brave|chrom|vivaldi|opera|edge/i.test(appName ?? "")) {
            const parts = b.split("\n\n");
            if (parts.length > 1 && parts[0].startsWith("<a"))
                b = parts.slice(1).join("\n\n");
        }
        return b.replace(/<[^>]*>/g, "");
    }

    // "now", "5m", "3h", "2d" (the card's time)
    function age(time) {
        const ms = Date.now() - time;
        if (ms < 60000)
            return "now";
        if (ms < 3600000)
            return Math.floor(ms / 60000) + "m";
        if (ms < 86400000)
            return Math.floor(ms / 3600000) + "h";
        return Math.floor(ms / 86400000) + "d";
    }

    // the history ------------------------------------------------------------
    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.cache/vtnc/notifications.json"
        printErrors: false
        onLoaded: root.loadHistory()
        onLoadFailed: root.historyLoaded = true
    }

    function loadHistory() {
        let saved = [];
        try {
            saved = JSON.parse(historyFile.text());
        } catch (e) {}
        const old = saved.slice(-keep).map(s => entryComponent.createObject(root, {
                id: root.nextId++,
                stored: s,
                fromHistory: true,
                time: Number(s.time) || 0
            }));
        // the ones that arrived meanwhile stay after them
        list = trimmed([...old, ...list]);
        historyLoaded = true;
        dropOld();
        save();
    }

    function save() {
        // (before the history is read it would be overwritten)
        if (historyLoaded)
            historyFile.setText(JSON.stringify(persist ? list.map(e => e.toJson()) : []));
    }
}
