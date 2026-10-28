import QtQuick
import qs.theme
import qs.services
import qs.dwidgets
import qs.kit as K
import "swidgets" as S
import "swidgets.js" as Catalog
import "../catalog.js" as DCatalog
import qs.dwidgets.quick

// Sliders: the Swidgets chosen in options.items (swidgets.js: volume, microphone, brightness, night
// light) as K.M3Sliders, side by side and vertical in a tall rect, else stacked, drawn by SliderView in
// the Iwidget family (2026-10-11): shapes · tones · tone, each also on the card. The mark does the
// Swidget's action (mute, sync, night light on / off).
// Nothing is written until the user moves a slider, and nothing while editing.
Dwidget {
    id: root

    // one model per Swidget, alive with the Dwidget
    readonly property var models: ({
            volume: volume,
            mic: mic,
            brightness: brightness,
            nightLight: nightLight
        })
    S.Volume {
        id: volume
    }
    S.Mic {
        id: mic
    }
    S.Brightness {
        id: brightness
    }
    S.NightLight {
        id: nightLight
    }

    readonly property var items: Catalog.items(options)

    // the Iwidget family (2026-10-11): shapes · tones · tone, each also on the card (DwidgetCard);
    // options: color (the tones' colour role), wavy (a wave while music plays, thin tracks), number
    readonly property bool card: DCatalog.isCard("sliders", root.style)
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

    SliderView {
        anchors.fill: parent
        anchors.margins: cardHost.pad
        models: root.models
        items: root.items
        editing: root.editing
        look: DCatalog.baseStyle("sliders", root.style)
        pal: cardHost.pal
        tone: colors.tone
        overTone: colors.overTone
        wavy: root.options?.wavy ?? true
        number: root.options?.number ?? true
    }
}
