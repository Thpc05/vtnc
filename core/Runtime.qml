pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Non-persistent shell state (lost on reload).
Singleton {
    id: root

    // Currently open app ("" = idle) and the screen it is shown on
    property string activeApp: ""
    property var activeAppArgs: ({})
    property string activeScreen: ""

    // Screens whose island was expanded by IPC/shortcut (screen name → true)
    property var pinnedExpanded: ({})
    // Screens whose idle island is expanded right now, for any reason (hover, pin, flash);
    // published by Island (screen name → true)
    property var expandedIslands: ({})

    function isIslandExpanded(screenName: string): bool {
        return expandedIslands[screenName] === true;
    }
    function setIslandExpanded(screenName: string, value: bool) {
        if (isIslandExpanded(screenName) === value)
            return;
        const m = Object.assign({}, expandedIslands);
        if (value)
            m[screenName] = true;
        else
            delete m[screenName];
        expandedIslands = m;
    }


    // the frame-rate meter in the log (`qs -c vtnc ipc call shell perf on`; island/PerfMeter.qml)
    property bool perf: false

    // emitted when an app that is already open is opened again with new args
    // (e.g. `launcher search <text>` while the launcher is open)
    signal reopened(string appId, var args)

    // Transient island states (OSD, notification), per screen: the island shows one for a while
    // over whatever it was showing (idle or an app) and then morphs back to it.
    // screen name → { kind, payload, duration (ms, 0 = until endTransient), serial }.
    // activeApp is never touched, so going back to the app is automatic.
    property var transients: ({})
    property int transientSerial: 0
    // a new notification shown only by the bell iwidget ("widget" mode): the bell on that screen
    // shakes, and appears for a moment if it's hidden in the island's current mode (Island)
    signal bellRang(string screenName)
    function ringBell(screenName: string) {
        bellRang(screenName);
    }

    // the volume OSD as its widget (osd.volumeWidget): the volume Iwidget on that screen's island
    // shows for a moment (Island)
    signal volumeFlashed(string screenName)
    function flashVolume(screenName: string) {
        volumeFlashed(screenName);
    }

    // a transient ended by an interruption (an app opened/closed, island IPC), not by its timer:
    // e.g. an interrupted notification goes back to its queue
    signal transientInterrupted(string screenName, string kind, var payload)

    function transientOn(screenName: string): var {
        return transients[screenName] ?? null;
    }

    // shows a transient on `screenName`, replacing the current one (another kind counts as
    // interrupted); the same kind again updates it in place (new payload, timer restarted, no morph)
    function showTransient(screenName: string, kind: string, payload: var, duration: int) {
        if (!screenName)
            return;
        const old = transients[screenName];
        const m = Object.assign({}, transients);
        m[screenName] = {
            kind: kind,
            payload: payload ?? {},
            duration: Math.max(0, duration ?? 0),
            serial: ++transientSerial
        };
        transients = m;
        if (old && old.kind !== kind)
            transientInterrupted(screenName, old.kind, old.payload);
    }

    // kind "" ends whatever is showing there
    function endTransient(screenName: string, kind: string) {
        const t = transients[screenName];
        if (!t || (kind && t.kind !== kind))
            return;
        const m = Object.assign({}, transients);
        delete m[screenName];
        transients = m;
    }

    // any explicit request (app, island IPC) cancels the transients right away, except a notification that
    // grows the island (island.notifications.presentation "grow"): it hangs under the app as well
    function interruptTransients() {
        const old = transients;
        const grows = Store.island.notifications?.presentation === "grow";
        const kept = {};
        const gone = [];
        for (const screenName in old) {
            if (grows && old[screenName].kind === "notification")
                kept[screenName] = old[screenName];
            else
                gone.push(screenName);
        }
        if (gone.length === 0)
            return;
        transients = kept;
        for (const screenName of gone)
            transientInterrupted(screenName, old[screenName].kind, old[screenName].payload);
    }

    // Follow the focused monitor while an app is open
    Connections {
        target: Hypr
        function onFocusedScreenChanged() {
            if (root.activeApp !== "" && Hypr.focusedScreen !== "")
                root.activeScreen = Hypr.focusedScreen;
        }
    }

    function isAppOpenOn(screenName: string): bool {
        return activeApp !== "" && activeScreen === screenName;
    }

    function openApp(appId: string, args: var) {
        interruptTransients();
        if (activeApp === appId) {
            activeAppArgs = args ?? {};
            reopened(appId, activeAppArgs);
            return;
        }
        activeAppArgs = args ?? {};
        activeScreen = Hypr.focusedScreen;
        activeApp = appId;
    }

    function closeApp() {
        interruptTransients();
        activeApp = "";
        activeAppArgs = {};
    }

    // Close the app and run `callback` once the island finished morphing back,
    // e.g. before taking a screenshot so the island isn't in it.
    function closeThen(callback: var) {
        closeApp();
        afterClose.callback = callback;
        afterClose.restart();
    }

    Timer {
        id: afterClose
        property var callback: null
        interval: Math.round(450 * Math.max(0, Store.theme.scale?.anim ?? 1)) + 150
        onTriggered: {
            const cb = callback;
            callback = null;
            cb?.();
        }
    }

    function toggleApp(appId: string) {
        if (activeApp === appId)
            closeApp();
        else
            openApp(appId, {});
    }

    function isPinned(screenName: string): bool {
        return pinnedExpanded[screenName] === true;
    }

    function setPinned(screenName: string, value: bool) {
        const m = Object.assign({}, pinnedExpanded);
        if (value)
            m[screenName] = true;
        else
            delete m[screenName];
        pinnedExpanded = m;
    }
}
