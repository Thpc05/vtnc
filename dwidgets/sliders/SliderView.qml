import QtQuick
import qs.theme
import qs.services
import qs.kit as K

// Sliders (2026-10-11, redone in the Iwidget family; the island's volume is its sibling): each Swidget
// is its mark (a click does its action: mute, sync, night light on / off), a K.M3Slider and, optionally,
// its percent. Rows stacked in a wide rect; columns side by side (the mark at the bottom, the number on
// top) in a rect at least as tall as wide. Looks:
//  - shapes: the mark a rounded square (muted) / an accent circle; a medium track in the accent
//  - tones: the mark a square in the tone (weak icon when muted); a thick track in the tone, its rest
//    a faint tone; the number bold in the tone
//  - tone: no fills: the icon, a thin track and the number in the tone
// `wavy`: the track waves while music plays, in every look (it thins to 4 px meanwhile, as the island's).
Item {
    id: root

    property var models: ({})
    property var items: []
    property bool editing: false
    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    property bool wavy: false
    property bool number: true

    readonly property int count: Math.max(1, items.length)
    readonly property bool vertical: height >= width
    readonly property int gap: K.Kit.spacing.medium
    readonly property bool shapes: look === "shapes"
    readonly property color accent: shapes ? pal.accent : tone
    readonly property color overAccent: shapes ? pal.overAccent : overTone

    K.StyledText {
        anchors.centerIn: parent
        visible: root.items.length === 0
        text: "No Swidgets chosen"
        color: root.pal.overVariant
    }

    Grid {
        id: grid
        anchors.fill: parent
        rows: root.vertical ? 1 : root.count
        columns: root.vertical ? root.count : 1
        spacing: root.gap

        readonly property real cellW: Math.floor(root.vertical ? (width - spacing * (root.count - 1)) / root.count : width)
        readonly property real cellH: Math.floor(root.vertical ? height : (height - spacing * (root.count - 1)) / root.count)
        // one mark size for all: even, 24…40
        readonly property real mark: 2 * Math.floor(Math.max(24, Math.min(40, root.vertical ? cellW : cellH)) / 2)
        // the slider's cross size (the handle's height): about twice the track, within the mark
        readonly property real cross: Math.min(mark, 2 * thickness + 12)
        // the track's thickness per look
        readonly property real thickness: root.look === "tone" ? 4 : root.look === "tones" ? 2 * Math.round(mark * 0.22) : 2 * Math.round(mark * 0.14)

        Repeater {
            model: root.items

            Item {
                id: level
                required property string modelData
                readonly property QtObject sw: root.models[modelData] ?? null
                readonly property bool on: !(sw?.muted ?? false)
                width: grid.cellW
                height: grid.cellH

                // a row: mark, track, number
                Mark {
                    id: rowMark
                    lv: level
                    visible: !root.vertical
                    y: Math.round((parent.height - height) / 2)
                }
                Percent {
                    id: rowNumber
                    lv: level
                    visible: !root.vertical && root.number
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: visible ? 32 : 0
                    horizontalAlignment: Text.AlignRight
                }
                Track {
                    lv: level
                    visible: !root.vertical
                    vertical: false
                    anchors.left: rowMark.right
                    anchors.leftMargin: Math.round(grid.mark * 0.3)
                    anchors.right: rowNumber.left
                    anchors.rightMargin: root.number ? Math.round(grid.mark * 0.2) : 0
                    anchors.verticalCenter: parent.verticalCenter
                    height: grid.cross
                }

                // a column: number, track, mark
                Percent {
                    id: colNumber
                    lv: level
                    visible: root.vertical && root.number
                    width: parent.width
                    height: visible ? 16 : 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Mark {
                    id: colMark
                    lv: level
                    visible: root.vertical
                    anchors.bottom: parent.bottom
                    x: Math.round((parent.width - width) / 2)
                }
                Track {
                    lv: level
                    visible: root.vertical
                    vertical: true
                    anchors.top: colNumber.bottom
                    anchors.topMargin: root.number ? 4 : 0
                    anchors.bottom: colMark.top
                    anchors.bottomMargin: Math.round(grid.mark * 0.3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: grid.cross
                }
            }
        }
    }

    // the Swidget's mark (QMark's language), its action on a click
    component Mark: Item {
        id: mark
        property Item lv
        readonly property bool on: lv.on
        width: grid.mark
        height: grid.mark

        Rectangle {
            anchors.fill: parent
            visible: root.look !== "tone" && (root.shapes || mark.on)
            radius: root.shapes && mark.on ? width / 2 : Math.round(width * 0.3)
            color: mark.on ? root.accent : root.pal.off
            Behavior on radius {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }
            Behavior on color {
                K.CAnim {}
            }
        }
        K.StateLayer {
            radius: root.shapes && mark.on ? width / 2 : Math.round(width * 0.3)
            color: mark.on && root.look !== "tone" ? root.overAccent : root.pal.over
            disabled: root.editing || !(mark.lv.sw?.ready ?? false)
            onClicked: mark.lv.sw?.iconClicked()
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            text: mark.lv.sw?.symbol ?? ""
            fill: mark.lv.sw?.iconFill ?? 1
            size: 2 * Math.round(grid.mark * 0.25)
            color: root.look === "tone" ? (mark.on ? root.tone : Qt.alpha(root.tone, 0.55)) : mark.on ? root.overAccent : root.shapes ? root.pal.over : Qt.alpha(root.tone, 0.55)
        }
    }

    component Percent: Text {
        property Item lv
        text: Math.round((lv.sw?.value ?? 0) * 100)
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 12
        font.weight: root.shapes ? Font.DemiBold : Font.Bold
        font.features: ({
                "tnum": 1
            })
        color: root.shapes ? root.pal.overVariant : lv.on ? root.tone : Qt.alpha(root.tone, 0.55)
    }

    component Track: K.M3Slider {
        id: track
        property Item lv
        // waving: the track thins to the island's 4 px (a thick stroke doesn't read as a wave) and
        // grows back when the music stops
        readonly property bool waving: root.wavy && MprisController.isPlaying && lv.on
        trackThickness: waving ? 4 : grid.thickness
        inactiveThickness: trackThickness
        Behavior on trackThickness {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        wavy: waving
        waveAmplitude: 2
        wavelength: 14
        activeColor: root.accent
        inactiveColor: root.shapes ? root.pal.track : Qt.alpha(root.tone, 0.2)
        muted: !lv.on
        valueIndicator: false
        interactive: !root.editing && (lv.sw?.ready ?? false)
        value: lv.sw?.value ?? 0
        onMoved: v => lv.sw?.set(v)
    }
}
