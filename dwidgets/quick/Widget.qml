import QtQuick
import qs.theme
import qs.dwidgets
import qs.kit as K
import "qwidgets" as Q
import "panels"
import "qwidgets.js" as Catalog
import "../catalog.js" as DCatalog

// Quick configs: the Qwidgets chosen in options.items (qwidgets.js) in the Iwidget family (2026-10-11):
// shapes · tones (two tones) · tone, each also on the card (`<look>Card`, DwidgetCard), drawn by
// QuickView. Options: color (the tones' colour role), gap, weight, labels (auto / on / off). The size
// arranges them (qwidgets.js); a style change fades through. Right-click on a Qwidget with a panel (a click for
// the Mixer) opens it: the Dwidget expands (to its expanded size) and fades through to the panel
// page (header + panel) on a card. Back returns to where it was (collapsed, or the expanded look).
// See ../README.md, "Quick configs".
Dwidget {
    id: root

    // one model per shown instance (Models.qml), alive with the Dwidget; `items` are their keys
    // ("caffeine#1"…: a Qwidget may repeat), what the views lay out
    readonly property var instances: Catalog.items(options)
    readonly property var models: modelSet.models
    Models {
        id: modelSet
        instances: root.instances
    }

    readonly property var items: instances.map(i => i.key)

    // the card variants draw the card (DwidgetCard); the look drawn: shapes · tones · tone
    readonly property bool card: DCatalog.isCard("quick", shownStyle)
    readonly property string face: DCatalog.baseStyle("quick", shownStyle)
    readonly property bool tones: face !== "shapes"

    // the entry's options: the tones' colour role, the gap, the weight (0 = the look's), the labels
    readonly property ToneColors colors: ToneColors {
        pal: root.pal
        role: root.options?.color || "primary"
    }
    readonly property int gap: (root.options?.gap ?? 0) > 0 ? root.options.gap : 8
    readonly property int weight: (root.options?.weight ?? 0) > 0 ? root.options.weight : face === "tones" ? 700 : face === "tone" ? 500 : 400

    // the panels follow the look (panels/*.qml read look.panel: kind = shapes / tones / tone, bare, in
    // its colours); `pal` is the palette under the panel (Kit.card, or Kit.bare without the card)
    readonly property var pal: cardHost.pal
    readonly property var look: ({
            panel: {
                kind: face,
                pal: pal,
                tone: colors.tone,
                overTone: colors.overTone,
                strong: tones ? colors.tone : pal.over,
                // stronger in light (55 % of the tone read 2.3:1 there)
                weak: tones ? Qt.alpha(colors.tone, K.Kit.expressive.light ? 0.85 : 0.62) : pal.overVariant,
                randomShapes: root.options?.randomShapes ?? true,
                faint: Qt.alpha(tones ? colors.tone : pal.over, 0.1)
            }
        })

    // panel ----------------------------------------------------------------------
    property string panelId: ""
    // the expanded size it asks the dashboard for: the Mixer's panel taller (its devices; user,
    // 2026-10-17), the others the catalog's
    readonly property string expandSize: Catalog.idOf(panelId) === "mixer" ? "6x7" : ""
    readonly property bool panelOpen: expanded && panelId !== ""
    // the panel expanded the Dwidget (back collapses it) vs it was already expanded (back returns
    // to the expanded look)
    property bool panelExpanded: false

    // any Qwidget with a panel opens it (right-click; the Mixer on a click), through Quick configs'
    // catalog expand (panel-only); `key` is the instance's
    function openPanel(key) {
        if (editing || !(Catalog.QWIDGETS[Catalog.idOf(key)]?.panel || models[key]?.opensPanel))
            return;
        panelExpanded = !expanded;
        panelId = key;
        if (!expanded)
            expandRequest(true);
    }

    function closePanel() {
        if (panelExpanded)
            expandRequest(false);
        else
            panelId = "";
    }

    // the look shown: follows `style`, swapped at the dip of a fade through
    property string shownStyle: style
    onStyleChanged: Qt.callLater(root.syncStyle)

    function syncStyle() {
        if (shownStyle === style)
            return;
        // hidden behind the panel (or about to be): swap at once
        if (!K.Kit.anim.enabled || panelOpen || toPanel.running || toContent.running || contentOpacity === 0) {
            shownStyle = style;
            return;
        }
        styleSwap.restart();
    }
    SequentialAnimation {
        id: styleSwap
        K.Anim {
            target: root
            property: "contentOpacity"
            to: 0
            type: K.Anim.FastEffects
        }
        ScriptAction {
            script: {
                root.shownStyle = root.style;
            }
        }
        K.Anim {
            target: root
            property: "contentOpacity"
            to: 1
            type: K.Anim.DefaultEffects
        }
    }

    // after the fade back, so the panel doesn't vanish mid-transition
    onExpandedChanged: if (!expanded)
        clearPanel.restart()
    Timer {
        id: clearPanel
        interval: K.Kit.anim.durations.expressiveDefaultSpatial
        onTriggered: if (!root.expanded)
            root.panelId = ""
    }

    // fade through between the Qwidgets and the panel (out on the fast effects curve, then in)
    property real contentOpacity: 1
    property real panelOpacity: 0

    onPanelOpenChanged: {
        styleSwap.stop();
        toPanel.stop();
        toContent.stop();
        (panelOpen ? toPanel : toContent).start();
    }
    SequentialAnimation {
        id: toPanel
        K.Anim {
            target: root
            property: "contentOpacity"
            to: 0
            type: K.Anim.FastEffects
        }
        K.Anim {
            target: root
            property: "panelOpacity"
            to: 1
            type: K.Anim.DefaultEffects
        }
    }
    SequentialAnimation {
        id: toContent
        K.Anim {
            target: root
            property: "panelOpacity"
            to: 0
            type: K.Anim.FastEffects
        }
        K.Anim {
            target: root
            property: "contentOpacity"
            to: 1
            type: K.Anim.DefaultEffects
        }
    }


    // the card (the Card variants), under the Qwidgets and the panel
    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        card: root.card
    }

    // Qwidgets ---------------------------------------------------------------------
    QuickView {
        id: view
        anchors.fill: parent
        anchors.margins: cardHost.pad
        randomShapes: root.options?.randomShapes ?? true
        layoutWidth: root.targetWidth - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
        layoutHeight: root.targetHeight - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
        visible: opacity > 0
        opacity: root.contentOpacity
        enabled: !root.editing
        models: root.models
        items: root.items
        look: root.face
        pal: root.pal
        tone: root.colors.tone
        overTone: root.colors.overTone
        gap: root.gap
        weight: root.weight
        labels: root.options?.labels || "auto"
        panels: root.expandable && !root.editing
        onOpenPanel: key => root.openPanel(key)
    }
    // panel page -------------------------------------------------------------------
    Item {
        id: panelPage
        anchors.fill: parent
        anchors.margins: K.Kit.padding.medium
        opacity: root.panelOpacity
        visible: opacity > 0

        PanelHeader {
            id: header
            width: parent.width
            look: root.look
            onBack: root.closePanel()
        }

        Loader {
            anchors.top: header.bottom
            anchors.topMargin: K.Kit.spacing.small
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            active: root.panelId !== ""
            sourceComponent: root.models[root.panelId]?.panel ?? null
            onLoaded: {
                if (item.hasOwnProperty("look"))
                    item.look = Qt.binding(() => root.look);
                if (item.hasOwnProperty("qwidget"))
                    item.qwidget = Qt.binding(() => root.models[root.panelId] ?? null);
            }
        }
    }
}
