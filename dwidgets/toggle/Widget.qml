import QtQuick
import qs.theme
import qs.dwidgets
import qs.dwidgets.quick.qwidgets as Q
import qs.dwidgets.quick.panels
import qs.kit as K
import qs.dwidgets.quick
import "../catalog.js" as DCatalog

// A Qwidget with a panel as a Dwidget of its own (`qid` picks it: Wi-Fi, Bluetooth, Mixer and, 2026-10-27,
// Color scheme, Power profile, Wallpaper; user: every toggle has a panel), in the Quick configs family
// (2026-10-11): shapes · tones · tone, each also on the card, drawn by Quick configs' QuickView with
// this one Qwidget (1x1 the mark; 2x1 / 3x1 / 2x2 the mark and its name and state; 1x2 the mark).
// Options: color, weight, labels (as Quick configs); the Mixer also `show` (output · input · apps).
// Its panel (networks, devices, the mixer…), scrolling when taller than the rect; its hero's mark and name are
// the switch (no switch in a header, 2026-10-27):
//  - 3x3 and up (2026-10-27): the panel is the Dwidget's face, always open, no header and no click event
//  - smaller: only expanded, at the catalog's size: a double click (or right-click, or the entry's event)
//    opens it with a back button; with the double click, a click waits for the double-click interval so
//    it doesn't toggle twice
Dwidget {
    id: root

    required property string qid

    // the Qwidget's live model (quick/qwidgets): title, symbol, active, status, panel, toggle()
    readonly property QtObject q: model.item
    Loader {
        id: model
        sourceComponent: ({
                wifi: wifiModel,
                bluetooth: bluetoothModel,
                mixer: mixerModel,
                colorScheme: schemeModel,
                powerProfile: powerModel,
                wallpaper: wallpaperModel
            })[root.qid] ?? null
    }
    Component {
        id: wifiModel
        Q.Wifi {}
    }
    Component {
        id: bluetoothModel
        Q.Bluetooth {}
    }
    Component {
        id: mixerModel
        Q.Mixer {}
    }
    Component {
        id: schemeModel
        Q.ColorScheme {}
    }
    Component {
        id: powerModel
        Q.PowerProfile {}
    }
    Component {
        id: wallpaperModel
        Q.Wallpaper {}
    }

    readonly property bool active: q?.active ?? false
    readonly property bool available: q?.available ?? false
    // the click split between the mark (toggle) and the rest (the panel): Wi-Fi and Bluetooth when their
    // name shows (with the mark alone, the entry's event decides as before)
    readonly property bool split: (qid === "wifi" || qid === "bluetooth") && view.arranged.kind !== "icons"
    // 3x3 and up the panel is the face (always open, no click event, no back); `size` is the expanded one
    // while expanded, so only at rest (a small toggle expanded keeps its back)
    readonly property bool panelFace: !expanded && size.w >= 3 && size.h >= 3 && (q?.panel ?? null) !== null
    // the panel: the face, or expanded
    readonly property bool showPanel: (expanded || panelFace) && (q?.panel ?? null) !== null

    // the look drawn (catalog style, 2026-10-11: the Quick configs family): shapes · tones · tone, each
    // also on the card (`<look>Card`)
    readonly property bool card: DCatalog.isCard(root.qid, root.style)
    readonly property string face: DCatalog.baseStyle(root.qid, root.style)
    readonly property var pal: cardHost.pal
    readonly property ToneColors colors: ToneColors {
        pal: root.pal
        role: root.options?.color || "primary"
    }
    readonly property int weight: (root.options?.weight ?? 0) > 0 ? root.options.weight : face === "tones" ? 700 : face === "tone" ? 500 : 400
    readonly property color strong: face === "shapes" ? pal.over : colors.tone
    readonly property color weak: face === "shapes" ? pal.overVariant : Qt.alpha(colors.tone, 0.55)

    // the panels' colours (quick/panels read look.panel)
    readonly property var look: ({
            panel: {
                kind: root.face,
                pal: root.pal,
                tone: root.colors.tone,
                overTone: root.colors.overTone,
                strong: root.strong,
                // the panels' weak text: stronger in light (55 % of the tone read 2.3:1 there)
                weak: root.face === "shapes" ? root.pal.overVariant : Qt.alpha(root.colors.tone, K.Kit.expressive.light ? 0.85 : 0.62),
                randomShapes: root.options?.randomShapes ?? true,
                faint: Qt.alpha(root.face === "shapes" ? root.pal.over : root.colors.tone, 0.1)
            }
        })

    // the card (the Card variants; behind the panel too)
    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        // the popup panel (expanded) sits on a card; the panel as the face follows the style (2026-10-27,
        // user: the Dwidget's own panel is a Dwidget, not a popup)
        card: root.card || (root.showPanel && !root.panelFace)
        opacity: root.available || root.showPanel ? 1 : 0.5
    }

    // the toggle: Quick configs' view with this one Qwidget (1x1 the mark; wider, the mark and its name
    // and state); the input is the toggle's own (below)
    Item {
        id: toggle
        anchors.fill: parent
        visible: !root.showPanel

        QuickView {
            id: view
            anchors.fill: parent
            anchors.margins: cardHost.pad
            randomShapes: root.options?.randomShapes ?? true
            layoutWidth: root.targetWidth - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
            layoutHeight: root.targetHeight - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
            interactive: false
            pressed: input.pressed && (!root.split || input.onMark)
            models: ({
                    [root.qid]: root.q
                })
            items: root.q ? [root.qid] : []
            look: root.face
            pal: root.pal
            tone: root.colors.tone
            overTone: root.colors.overTone
            weight: root.weight
            labels: root.options?.labels || "auto"
        }

        K.StateLayer {
            id: input
            radius: cardHost.radius
            color: root.strong
            disabled: root.editing || !root.available || root.panelFace
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            // where the press landed (split: only the mark looks pressed)
            property bool onMark: false
            onPressed: m => {
                const p = mapToItem(view, m.x, m.y);
                onMark = view.onMark(p.x, p.y);
            }

            // split (Wi-Fi / Bluetooth with their name beside the mark): the mark toggles, the rest opens
            // the panel, whatever the entry's event. Otherwise the entry's event decides the left click:
            // double click → toggle after the double-click interval (a double click expands instead);
            // click → expand (the panel header has the switch); hover / none → toggle at once.
            onClicked: m => {
                if (m.button === Qt.RightButton) {
                    if (root.expandable)
                        root.expandRequest(!root.expanded);
                } else if (root.split) {
                    if (onMark)
                        root.q.toggle();
                    else
                        root.expandRequest(true);
                } else if (root.trigger === "doubleclick") {
                    single.restart();
                } else if (root.trigger === "click") {
                    root.expandRequest(!root.expanded);
                } else {
                    root.q.toggle();
                }
            }
            onDoubleClicked: m => {
                if (m.button !== Qt.LeftButton || root.split || root.trigger !== "doubleclick")
                    return;
                single.stop();
                root.expandRequest(!root.expanded);
            }
        }
        Timer {
            id: single
            interval: Qt.styleHints.mouseDoubleClickInterval
            onTriggered: root.q?.toggle()
        }
    }

    // the panel -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        // the face: the Dwidget's padding (none without a card, as the others); the popup: the card's
        anchors.margins: root.panelFace ? cardHost.pad : K.Kit.padding.medium
        visible: root.showPanel

        // the back arrow, only when it was opened by expanding (the face has no header; the hero's mark
        // and name are the switch, 2026-10-27)
        PanelHeader {
            id: header
            width: parent.width
            visible: !root.panelFace
            look: root.look
            onBack: root.expandRequest(false)
        }
        // a panel taller than the rect scrolls (its implicitHeight; the ones with their own list fill it)
        Flickable {
            id: panelScroll
            anchors.top: header.visible ? header.bottom : parent.top
            anchors.topMargin: header.visible ? K.Kit.spacing.small : 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentWidth: width
            contentHeight: Math.max(height, panelLoader.item?.implicitHeight ?? 0)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Loader {
                id: panelLoader
                width: panelScroll.width
                height: panelScroll.contentHeight
                active: root.showPanel
                sourceComponent: root.q?.panel ?? null
                onLoaded: {
                    if (item.hasOwnProperty("look"))
                        item.look = Qt.binding(() => root.look);
                    if (item.hasOwnProperty("qwidget"))
                        item.qwidget = Qt.binding(() => root.q);
                    // the Mixer: what it shows (options.show)
                    if (item.hasOwnProperty("show"))
                        item.show = Qt.binding(() => root.options?.show ?? ["output", "input", "apps"]);
                }
            }
        }
    }
}
