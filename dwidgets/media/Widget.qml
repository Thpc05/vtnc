import QtQuick
import qs.dwidgets
import qs.dwidgets.quick
import "../catalog.js" as DCatalog

// The media player in the Iwidget family (2026-10-11): shapes · tones · tone, and disc (the extra:
// the art a turning record in its wavy ring), each also on the card (DwidgetCard), drawn by MediaView.
// The size picks the layout: one row tall a strip, clearly wider the art at the left, clearly taller the
// art on top, else (about square: 2x2 … 5x4, 3x2, 4x3) the art big with the controls beside it. Options: color (the tones' colour role), art, wavy, times. A right click opens
// the player picker (Picker: Automatic or a pinned app).
Dwidget {
    id: root

    readonly property bool card: DCatalog.isCard("media", root.style)
    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        card: root.card
    }
    ToneColors {
        id: colors
        pal: cardHost.pal
        role: root.options?.color || "primary"
    }

    MediaView {
        anchors.fill: parent
        anchors.margins: cardHost.pad
        look: DCatalog.baseStyle("media", root.style)
        pal: cardHost.pal
        tone: colors.tone
        overTone: colors.overTone
        interactive: !root.editing
        showArt: root.options?.art ?? true
        wavy: root.options?.wavy ?? true
        showTimes: root.options?.times ?? true
        layout: root.size.h === 1 ? "strip" : height >= width * 1.25 ? "tall" : width >= height * 1.6 ? "wide" : "block"
        onPickPlayer: picker.open = true
    }

    Picker {
        id: picker
        radius: cardHost.card ? cardHost.radius : 0
    }
}
