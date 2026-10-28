import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.core
import qs.services
import qs.theme
import qs.kit as K
import qs.iwidgets.tray as Tray

// The dock (2026-10-15): one icon per app, with up to three dots under it counting its windows (the
// focused app's in the accent). Per island mode (island.dock.compact / expanded):
//  - content: "dock" (the pinned apps first, in their order, then the other open ones) or "open" (only
//    the open ones; it collapses with none)
//  - scope: "workspace" (the windows on this monitor's workspace) or "all" (every workspace)
// Looks:
//  - icons: the apps' own icons; a pinned app with no window is faded
//  - tint: each icon tinted (the tray's Tint), the focused app in the accent, the others in the ink
// A click focuses the app's window (focused already: the next of its windows), or opens the app
// without one; a middle click opens a new window; a right click opens its menu (pin / unpin, new
// window, close). The pinned apps are island.dock.pinned (desktop entry ids).
Item {
    id: root

    property string style: "icons"
    property ShellScreen screen: null
    property string mode: "compact"
    property var pal: K.Kit.bare

    readonly property var options: Store.island.dock?.[mode] ?? ({})
    readonly property bool showPinned: (options.content ?? "dock") === "dock"
    readonly property bool allWorkspaces: options.scope === "all"
    readonly property var pinned: Store.island.dock?.pinned ?? []

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property int workspaceId: monitor?.activeWorkspace?.id ?? Hypr.focusedWorkspace?.id ?? 1

    function appIdOf(t): string {
        return t?.wayland?.appId || t?.lastIpcObject?.class || "";
    }
    // an app's desktop entry: by its id (a pinned key), else guessed from a window's app id
    function entryFor(key: string, appId: string): var {
        return DesktopEntries.byId(key) ?? (appId !== "" ? DesktopEntries.heuristicLookup(appId) : null);
    }
    // an app's key: its desktop entry's id (what's pinned), else its app id
    function keyOf(appId: string): string {
        return DesktopEntries.heuristicLookup(appId)?.id ?? appId.toLowerCase();
    }

    // the windows counted (special workspaces never)
    readonly property var windows: Hypr.toplevels.filter(t => appIdOf(t) !== "" && (allWorkspaces ? (t.workspace?.id ?? 0) > 0 : t.workspace?.id === workspaceId))

    // the apps shown, in order: { key, appId, windows }
    readonly property var apps: {
        const byKey = {};
        const order = [];
        for (const t of windows) {
            const appId = appIdOf(t);
            const k = keyOf(appId);
            if (!byKey[k]) {
                byKey[k] = {
                    key: k,
                    appId: appId,
                    windows: []
                };
                order.push(k);
            }
            byKey[k].windows.push(t);
        }
        const out = [];
        if (showPinned)
            for (const k of pinned)
                out.push(byKey[k] ?? {
                    key: k,
                    appId: "",
                    windows: []
                });
        for (const k of order)
            if (!showPinned || !pinned.includes(k))
                out.push(byKey[k]);
        return out;
    }
    readonly property var byKey: {
        const m = {};
        for (const a of apps)
            m[a.key] = a;
        return m;
    }

    // The icons are a ListModel of keys kept in step with `apps` (an array model would make every icon
    // again each time a window opens, closes or the workspace changes)
    ListModel {
        id: cells
    }
    function sync() {
        const keys = apps.map(a => a.key);
        for (let i = cells.count - 1; i >= 0; i--)
            if (!keys.includes(cells.get(i).key))
                cells.remove(i);
        keys.forEach((k, i) => {
            let j = -1;
            for (let x = i; x < cells.count; x++)
                if (cells.get(x).key === k) {
                    j = x;
                    break;
                }
            if (j < 0)
                cells.insert(i, {
                    key: k
                });
            else if (j !== i)
                cells.move(j, i, 1);
        });
    }
    onAppsChanged: sync()
    Component.onCompleted: sync()

    function togglePin(key: string) {
        Store.island.dock.pinned = pinned.includes(key) ? pinned.filter(k => k !== key) : pinned.concat([key]);
    }
    function launch(entry) {
        if (entry)
            Apps.launch(entry);
    }
    // focus the app: a window of it, or the next one when it's focused already
    function focusApp(app) {
        const ws = app.windows;
        const i = ws.findIndex(w => w.activated);
        const next = i < 0 ? ws[0] : ws[(i + 1) % ws.length];
        if (next && !(i >= 0 && ws.length === 1))
            next.wayland?.activate();
    }

    readonly property int cell: 24
    readonly property int spacing: 2
    implicitWidth: cells.count > 0 ? cells.count * cell + (cells.count - 1) * spacing : 0
    implicitHeight: 26

    Row {
        spacing: root.spacing

        add: Transition {
            K.Anim {
                property: "scale"
                from: 0.4
                to: 1
                type: K.Anim.FastSpatial
            }
            K.Anim {
                property: "opacity"
                from: 0
                to: 1
                type: K.Anim.FastEffects
            }
        }
        move: Transition {
            K.Anim {
                property: "x"
                type: K.Anim.DefaultSpatial
            }
        }

        Repeater {
            model: cells

            Item {
                id: app
                required property string key
                readonly property var info: root.byKey[key] ?? null
                readonly property var windows: info?.windows ?? []
                readonly property var entry: root.entryFor(key, info?.appId ?? "")
                readonly property string icon: Quickshell.iconPath(entry?.icon || (info?.appId || key).toLowerCase(), true)
                readonly property bool running: windows.length > 0
                readonly property bool focused: windows.some(w => w.activated)
                readonly property bool pinned: root.pinned.includes(key)

                width: root.cell
                height: root.implicitHeight

                // hover: a soft circle behind the icon (in the ink)
                Rectangle {
                    x: Math.round((parent.width - 22) / 2)
                    width: 22
                    height: 22
                    radius: 11
                    color: root.pal.over
                    opacity: mouse.containsMouse ? 0.1 : 0
                    Behavior on opacity {
                        K.Anim {
                            type: K.Anim.FastEffects
                        }
                    }
                }

                Tray.TintedIcon {
                    readonly property int size: 18
                    x: Math.round((parent.width - size) / 2)
                    y: Math.round((22 - size) / 2)
                    implicitSize: size
                    source: app.icon
                    tint: root.style === "tint"
                    colour: app.focused ? root.pal.accent : root.pal.over
                    // a pinned app with no window: faded
                    opacity: app.running ? 1 : 0.5
                }

                // the windows: a dot each, up to three
                Row {
                    x: Math.round((parent.width - width) / 2)
                    y: 23
                    spacing: 2
                    Repeater {
                        model: Math.min(3, app.windows.length)
                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: app.focused ? root.pal.accent : root.pal.overVariant
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: m => {
                        if (m.button === Qt.RightButton)
                            menu.open(app);
                        else if (m.button === Qt.MiddleButton || !app.running)
                            root.launch(app.entry);
                        else
                            root.focusApp(app.info);
                    }
                }
            }
        }
    }

    DockMenu {
        id: menu
        onTogglePin: key => root.togglePin(key)
        onLaunch: entry => root.launch(entry)
    }
}
