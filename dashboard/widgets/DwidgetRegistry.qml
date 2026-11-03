pragma Singleton

import QtQuick
import Quickshell
import "catalog.js" as Catalog

// A directory import per widget folder, on purpose unused: a URL load alone doesn't tell
// Quickshell's hot reload to watch those files (the trailing comment keeps
// tools/unused-imports.py from dropping them).
import qs.dashboard.widgets.calendar // hot reload
import qs.dashboard.widgets.clock // hot reload
import qs.dashboard.widgets.image // hot reload
import qs.dashboard.widgets.media // hot reload
import qs.dashboard.widgets.placeholder // hot reload
import qs.dashboard.widgets.quick // hot reload
import qs.dashboard.widgets.sliders // hot reload
import qs.dashboard.widgets.summary // hot reload
import qs.dashboard.widgets.toggle // hot reload
import qs.dashboard.widgets.visualizer // hot reload

// Dashboard widgets (Dwidgets) available to the dashboard and to the settings app.
// Each one is described in its folder's meta.js (index.js collects them, catalog.js adds the card
// variants) and drawn by that folder's Widget.qml, a Dwidget (Dwidget.qml: widgetId, style, size,
// expanded, expandable, options, editing, expandRequest). A folder may draw several Dwidgets and tell
// them apart by `widgetId` (toggle, summary). Entries have two modes, idle and expanded, each
// { style, size }.
// The cell loads the file by URL ([[isolation by URL]]: a broken Dwidget fails in its own cell).
// To add one, see README.md ("Adding a Dwidget").
Singleton {
    id: root

    // id → { title, icon, styles, defaults, … } from the widget's meta.js
    readonly property var widgets: Catalog.WIDGETS

    // the Widget.qml that draws Dwidget `id` ("" when the id is unknown): several ids may share one
    function url(id: string): url {
        const folder = Catalog.FOLDERS[id];
        return folder ? Qt.resolvedUrl(folder + "/Widget.qml") : "";
    }

    function styles(id: string): var {
        return widgets[id]?.styles ?? [];
    }

    // "3x2" → { w: 3, h: 2 } (null if malformed)
    function parseSize(size: string): var {
        return Catalog.parseSize(size);
    }

    // the entry's expanded size ("WxH")
    function expandedSize(entry: var): string {
        return Catalog.expandedSize(entry) ?? "";
    }

    // a valid { style, size } for Dwidget `id` (a bad style → fallback's, a bad size → the style's first)
    function validMode(id: string, mode: var, fallback: var): var {
        return Catalog.validMode(id, mode, fallback);
    }

    // a Card variant (the style draws DwidgetCard)
    function isCard(id: string, style: string): bool {
        return Catalog.isCard(id, style);
    }

    // whether Dwidget `id` expands (the catalog's `expand`)
    function expands(id: string): bool {
        return Catalog.expands(id);
    }
    // whether its expand event is the user's to pick (not a panel-only expansion)
    function hasEvent(id: string): bool {
        return Catalog.hasEvent(id);
    }

    // the entry's expand event (click · doubleclick · hover · none)
    function trigger(entry: var): string {
        return Catalog.trigger(entry);
    }

    function defaultEntry(id: string, uid: string, x: int, y: int): var {
        return Catalog.defaultEntry(id, uid, x, y);
    }
}
