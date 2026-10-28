pragma Singleton

import QtQuick
import Quickshell
import qs.iwidgets.workspaces as Workspaces
import qs.iwidgets.clock as Clock
import qs.iwidgets.date as DateWidget
import qs.iwidgets.media as Media
import qs.iwidgets.recording as Recording
import qs.iwidgets.tray as Tray
import qs.iwidgets.volume as Volume
import qs.iwidgets.battery as Battery
import qs.iwidgets.notifications as Notifications
import qs.iwidgets.quick as Quick
import qs.iwidgets.visualizer as Visualizer
import qs.iwidgets.window as ActiveWindow
import qs.iwidgets.dock as Dock
import "../iwidgets/catalog.js" as Catalog

// Island widgets (Iwidgets) available to the idle view and to the settings app.
// Each widget lives in iwidgets/<id>/Widget.qml and gets `style: string` (the look to render now,
// see iwidgets/catalog.js), `growing: bool` (the island's direction, for the shared ContentAnim curve)
// and `screen` if it declares it.
// Widgets are imported (not loaded by URL) so Quickshell's hot reload tracks their files.
// To add one: create iwidgets/<id>/Widget.qml, describe it in iwidgets/catalog.js, import it here,
// add it to `components` and to defaults/config/island.json.
Singleton {
    id: root

    // title / icon / styles / defaults come from iwidgets/catalog.js; the components are here
    readonly property var components: ({
            workspaces: workspacesComponent,
            clock: clockComponent,
            date: dateComponent,
            media: mediaComponent,
            recording: recordingComponent,
            tray: trayComponent,
            volume: volumeComponent,
            battery: batteryComponent,
            notifications: notificationsComponent,
            quick: quickComponent,
            visualizer: visualizerComponent,
            window: windowComponent,
            dock: dockComponent
        })

    // id → { title, icon, styles: [{ id, title }], defaults: { compact, expanded }, component }
    readonly property var widgets: {
        const out = {};
        for (const id in Catalog.WIDGETS)
            if (components[id])
                out[id] = Object.assign({ component: components[id] }, Catalog.WIDGETS[id]);
        return out;
    }

    readonly property string hidden: Catalog.HIDDEN

    function styles(id: string): var {
        return widgets[id]?.styles ?? [];
    }

    function defaultStyle(id: string, mode: string): string {
        return Catalog.defaultStyle(id, mode);
    }

    // card variants (iwidgets/catalog.js): what the widget renders, whether a card is drawn, a parent
    // style's Card variant ("" without one), and the parents the settings list
    function baseStyle(id: string, style: string): string {
        return Catalog.baseStyle(id, style);
    }
    function isCard(id: string, style: string): bool {
        return Catalog.isCard(id, style);
    }
    function cardVariant(id: string, base: string): string {
        return Catalog.cardVariant(id, base);
    }
    function parents(id: string): var {
        return Catalog.parents(id);
    }

    function has(id: string): bool {
        return widgets[id] !== undefined;
    }

    function component(id: string): Component {
        return widgets[id]?.component ?? null;
    }

    Component {
        id: workspacesComponent
        Workspaces.Widget {}
    }
    Component {
        id: clockComponent
        Clock.Widget {}
    }
    Component {
        id: dateComponent
        DateWidget.Widget {}
    }
    Component {
        id: mediaComponent
        Media.Widget {}
    }
    Component {
        id: recordingComponent
        Recording.Widget {}
    }
    Component {
        id: trayComponent
        Tray.Widget {}
    }
    Component {
        id: volumeComponent
        Volume.Widget {}
    }
    Component {
        id: batteryComponent
        Battery.Widget {}
    }
    Component {
        id: notificationsComponent
        Notifications.Widget {}
    }
    Component {
        id: quickComponent
        Quick.Widget {}
    }
    Component {
        id: visualizerComponent
        Visualizer.Widget {}
    }
    Component {
        id: windowComponent
        ActiveWindow.Widget {}
    }
    Component {
        id: dockComponent
        Dock.Widget {}
    }
}
