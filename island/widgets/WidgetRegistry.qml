pragma Singleton

import QtQuick
import Quickshell
import "catalog.js" as Catalog

// A directory import per widget folder, on purpose unused: a URL load alone doesn't tell
// Quickshell's hot reload to watch those files (the trailing comment keeps
// tools/unused-imports.py from dropping them).
import qs.island.widgets.battery // hot reload
import qs.island.widgets.clock // hot reload
import qs.island.widgets.date // hot reload
import qs.island.widgets.dock // hot reload
import qs.island.widgets.media // hot reload
import qs.island.widgets.notifications // hot reload
import qs.island.widgets.quick // hot reload
import qs.island.widgets.recording // hot reload
import qs.island.widgets.tray // hot reload
import qs.island.widgets.visualizer // hot reload
import qs.island.widgets.volume // hot reload
import qs.island.widgets.window // hot reload
import qs.island.widgets.workspaces // hot reload

// Island widgets (Iwidgets) available to the idle view and to the settings app.
// Each widget lives in island/widgets/<id>/, which describes itself in meta.js (title, icon, styles,
// defaults; index.js collects them) and draws itself in Widget.qml. The frame loads that file by URL
// ([[isolation by URL]]: a broken widget fails in its own slot) and gives it `style` (the look to
// render now), `growing` (the island's direction, for the shared ContentAnim curve) and `screen` if
// it declares them.
// To add one: create island/widgets/<id>/ with Widget.qml and meta.js, run tools/check (it writes
// index.js) and add it to defaults/config/island.json.
Singleton {
    id: root

    // id → { title, icon, styles: [{ id, title }], defaults: { compact, expanded } }
    readonly property var widgets: Catalog.WIDGETS

    readonly property string hidden: Catalog.HIDDEN

    // the widget's own Widget.qml ("" when the id is unknown)
    function url(id: string): url {
        return has(id) ? Qt.resolvedUrl(Catalog.FOLDERS[id] + "/Widget.qml") : "";
    }

    function styles(id: string): var {
        return widgets[id]?.styles ?? [];
    }

    function defaultStyle(id: string, mode: string): string {
        return Catalog.defaultStyle(id, mode);
    }

    // card variants (catalog.js): what the widget renders, whether a card is drawn, a parent
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
}
