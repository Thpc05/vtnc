import QtQuick
import qs.base.kit as K
import qs.island.widgets

// Hosts one Iwidget in one style, for the island (island/WidgetSlot.qml) and the settings preview
// (settings/pages/island/WidgetPreview.qml): a card variant (catalog.js, "<base>Card")
// draws the island card behind it (Kit.cardFor(cardColor), else Appearance → General → Cards) and the widget
// only gets the base style. The widget also gets, when it declares them, `pal` (the card's palette,
// or Kit.bare without one), `mode` (compact / expanded), `growing` and `screen`.
Item {
    id: root

    property string widgetId
    // the chosen style, card variants included (never "hidden")
    property string style
    property string mode: "compact"
    property bool growing: true
    property var screen: null
    // the width a `fillsSlot` widget lays itself out in (the host's animated width, card included)
    property real fillWidth: 0
    // already on a card (an island section's, island.anchors): the card's palette, no card of its own
    // (the same colour: it would vanish into it)
    property bool inCard: false

    readonly property bool card: WidgetRegistry.isCard(widgetId, style) && !inCard
    // the card's own colour (the entry's cardColor; "" = the global one); a section card is the global one
    property string cardColor: ""
    readonly property var cardPal: K.Kit.cardFor(cardColor)
    readonly property string base: WidgetRegistry.baseStyle(widgetId, style)
    readonly property Item widget: loader.item
    // the widget's file didn't load (a broken widget fails in its own slot): a mark stands in for it
    readonly property bool broken: loader.status === Loader.Error
    readonly property bool fills: widget?.fillsSlot ?? false
    readonly property real padX: card ? K.Kit.padding.small : 0
    readonly property real padY: card ? 3 : 0

    // final width (not animated), card included; 0 when the widget has nothing to show
    readonly property real widgetWidth: broken ? mark.implicitWidth : widget ? (widget.targetWidth ?? widget.implicitWidth) : 0
    readonly property real targetWidth: widgetWidth > 0 ? widgetWidth + 2 * padX : 0

    implicitWidth: broken ? mark.implicitWidth + 2 * padX : widget && widget.implicitWidth > 0 ? widget.implicitWidth + 2 * padX : 0
    implicitHeight: broken ? Math.max(mark.implicitHeight + 2 * padY, card ? 26 : 0) : widget ? Math.max(widget.implicitHeight + 2 * padY, card ? 26 : 0) : 0

    // the card
    Rectangle {
        anchors.fill: parent
        visible: root.card && root.widgetWidth > 0
        radius: height / 2
        color: root.cardPal.fill
        Behavior on color {
            K.CAnim {}
        }
    }

    Loader {
        id: loader
        x: root.padX
        anchors.verticalCenter: parent.verticalCenter
        source: WidgetRegistry.url(root.widgetId)
        // a broken widget fails here only: the island and its other slots keep running
        onStatusChanged: if (status === Loader.Error)
            console.warn(`[Iwidget] "${root.widgetId}" failed to load`);
        onLoaded: {
            if (item.fillsSlot ?? false)
                item.width = Qt.binding(() => Math.max(0, root.fillWidth - 2 * root.padX));
            item.style = Qt.binding(() => root.base);
            if (item.hasOwnProperty("pal"))
                item.pal = Qt.binding(() => root.card ? root.cardPal : root.inCard ? K.Kit.islandCard : K.Kit.bare);
            if (item.hasOwnProperty("mode"))
                item.mode = Qt.binding(() => root.mode);
            if (item.hasOwnProperty("growing"))
                item.growing = Qt.binding(() => root.growing);
            if (item.hasOwnProperty("screen"))
                item.screen = Qt.binding(() => root.screen);
        }
    }

    // "failed to load": the broken widget's slot, not the island
    K.MaterialIcon {
        id: mark
        anchors.centerIn: parent
        visible: root.broken
        text: "warning"
        size: 16
        color: root.cardPal.over
    }
}
