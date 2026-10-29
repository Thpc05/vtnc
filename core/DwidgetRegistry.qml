pragma Singleton

import QtQuick
import Quickshell
import qs.dwidgets.placeholder as Placeholder
import qs.dwidgets.media as Media
import qs.dwidgets.quick as Quick
import qs.dwidgets.calendar as Calendar
import qs.dwidgets.sliders as Sliders
import qs.dwidgets.toggle as Toggle
import qs.dwidgets.summary as Summary
import qs.dwidgets.image as Image
import qs.dwidgets.clock as Clock
import qs.dwidgets.visualizer as Visualizer
import "../dwidgets/catalog.js" as Catalog

// Dashboard widgets (Dwidgets) available to the dashboard and to the settings app.
// Each one lives in dwidgets/<id>/Widget.qml, is a Dwidget (dwidgets/Dwidget.qml: style, size,
// expanded, expandable, growing, options, editing, expandRequest) and is described in
// dwidgets/catalog.js. Entries have two modes, idle and expanded, each { style, size }.
// Imported (not loaded by URL) so Quickshell's hot reload tracks their files.
// To add one, see dwidgets/README.md ("Adding a Dwidget").
Singleton {
    id: root

    // title / icon / styles / defaults come from dwidgets/catalog.js; the components are here
    readonly property var components: ({
            placeholder: placeholderComponent,
            media: mediaComponent,
            quick: quickComponent,
            calendar: calendarComponent,
            sliders: slidersComponent,
            mixer: mixerComponent,
            wifi: wifiComponent,
            bluetooth: bluetoothComponent,
            colorScheme: schemeComponent,
            powerProfile: powerComponent,
            wallpaper: wallpaperComponent,
            notifications: notificationsComponent,
            clipboard: clipboardComponent,
            notes: notesComponent,
            dino: dinoComponent,
            image: imageComponent,
            clock: clockComponent,
            visualizer: visualizerComponent
        })

    // id → { title, icon, styles, defaults, component }
    readonly property var widgets: {
        const out = {};
        for (const id in Catalog.WIDGETS)
            if (components[id])
                out[id] = Object.assign({
                    component: components[id]
                }, Catalog.WIDGETS[id]);
        return out;
    }

    function component(id: string): Component {
        return widgets[id]?.component ?? null;
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

    Component {
        id: placeholderComponent
        Placeholder.Widget {}
    }
    Component {
        id: mediaComponent
        Media.Widget {}
    }
    Component {
        id: quickComponent
        Quick.Widget {}
    }
    Component {
        id: calendarComponent
        Calendar.Widget {}
    }
    Component {
        id: slidersComponent
        Sliders.Widget {}
    }
    Component {
        id: mixerComponent
        Toggle.Widget {
            qid: "mixer"
        }
    }
    Component {
        id: wifiComponent
        Toggle.Widget {
            qid: "wifi"
        }
    }
    Component {
        id: bluetoothComponent
        Toggle.Widget {
            qid: "bluetooth"
        }
    }
    Component {
        id: schemeComponent
        Toggle.Widget {
            qid: "colorScheme"
        }
    }
    Component {
        id: powerComponent
        Toggle.Widget {
            qid: "powerProfile"
        }
    }
    Component {
        id: wallpaperComponent
        Toggle.Widget {
            qid: "wallpaper"
        }
    }
    Component {
        id: notificationsComponent
        Summary.Widget {
            kind: "notifications"
        }
    }
    Component {
        id: clipboardComponent
        Summary.Widget {
            kind: "clipboard"
        }
    }
    Component {
        id: notesComponent
        Summary.Widget {
            kind: "notes"
        }
    }
    Component {
        id: dinoComponent
        Summary.Widget {
            kind: "dino"
        }
    }
    Component {
        id: imageComponent
        Image.Widget {}
    }
    Component {
        id: clockComponent
        Clock.Widget {}
    }
    Component {
        id: visualizerComponent
        Visualizer.Widget {}
    }
}
