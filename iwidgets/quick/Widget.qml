import QtQuick
import qs.core
import qs.theme
import qs.kit as K
import "../../dwidgets/quick" as DQ
import "../../dwidgets/quick/qwidgets.js" as Qw

// The dashboard's Quick configs on the island (2026-10-09): the Qwidgets of island.quick.items
// (Island → Layout), each a small mark that toggles on a click; toggle only (no panels from the
// island yet; the Mixer, which only opens a panel, is left out). The Qwidget models are the
// dashboard's (dwidgets/quick/qwidgets), alive only while shown. Styles (the marks are the dashboard's,
// dwidgets/quick/QMark.qml):
//  - shapes: a rounded square off, an accent circle on (morphing)
//  - tones: a weak bare icon off, an accent rounded square on
//  - tone (2026-10-11): no fills, the icon in the tone, on = filled and heavier
// Each also comes on the island card (Card variants: `pal`).
Item {
    id: root

    property string style: "shapes"
    // from the frame: the palette (the island card's, or the bare island's)
    property var pal: K.Kit.bare

    // the shown instances (a Qwidget may repeat; the Mixer, which only opens a panel, is left out) and
    // their models (dwidgets/quick/Models.qml); `items` are their keys
    readonly property var instances: Qw.items(Store.island.quick ?? null, true)
    readonly property var items: instances.map(i => i.key)
    DQ.Models {
        id: modelSet
        instances: root.instances
    }
    readonly property int mark: 22
    // island.quick: gap (px), weight (300…1500, 0 = the style's: shapes 400, tones 700, tone 500;
    // emboldened past 700 by the mark) and the tones' colour role (as the tray's tint)
    readonly property int gap: Store.island.quick?.gap ?? 4
    readonly property int iconWeight: (Store.island.quick?.weight ?? 0) > 0 ? Store.island.quick.weight : style === "tones" ? 700 : style === "tone" ? 500 : 400
    DQ.ToneColors {
        id: colors
        pal: root.pal
        role: Store.island.quick?.color || "primary"
    }

    implicitWidth: items.length > 0 ? items.length * mark + (items.length - 1) * gap : 0
    implicitHeight: 24

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            model: root.items

            DQ.QMark {
                id: entry
                required property string modelData
                width: root.mark
                height: root.mark
                q: modelSet.models[modelData] ?? null
                look: root.style
                pal: root.pal
                tone: colors.tone
                overTone: colors.overTone
                weight: root.iconWeight
                iconSize: 14
                pressed: input.pressed

                K.StateLayer {
                    id: input
                    radius: entry.shapeRadius
                    color: entry.on ? entry.overAccent : root.pal.over
                    disabled: !(entry.q?.available ?? true)
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: m => m.button === Qt.RightButton ? entry.q?.alternate?.() : entry.q?.toggle()
                }
            }
        }
    }
}
