import QtQuick
import qs.services
import qs.dwidgets
import qs.kit as K

// The media player in the Iwidget family (2026-10-11, redone from scratch in the island's language;
// the island's media is its sibling). Looks:
//  - shapes: the art a rounded square; play an accent rounded square that rounds into a circle while
//    playing; previous / next on rounded squares (pal.off); a medium accent track
//  - tones: the title bold in the tone, the artist and times a weak tone of it; play bare in the tone,
//    a tone square while playing (the Qwidget marks); a thick track in the tone
//  - tone: everything in the tone, no fills; a thin track
//  - disc (the extra, as the island's): Shapes with the art a record turning while playing, its
//    progress a wavy ring around it when there's room
// Layouts (from the size, Widget.qml): strip (a row: art · texts · controls), wide (clearly wider: the art
// at the left), block (about square, 2x2 … 5x4: the art big with the controls beside it, the texts and
// progress under), tall (the art big on top). Options: color, art, wavy (the
// progress waves while playing, thinning meanwhile), times. The wheel skips, a right click picks the
// player (pickPlayer).
Item {
    id: root

    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    property bool interactive: true
    property bool showArt: true
    property bool wavy: true
    property bool showTimes: true
    // strip · square · wide · tall
    property string layout: "wide"
    signal pickPlayer

    readonly property bool disc: look === "disc"
    readonly property bool shapes: look === "shapes" || disc
    readonly property color strong: shapes ? pal.over : tone
    readonly property color weak: shapes ? pal.overVariant : Qt.alpha(tone, look === "tone" ? 0.7 : 0.55)
    readonly property color accent: shapes ? pal.accent : tone
    readonly property color overAccent: shapes ? pal.overAccent : overTone

    // the scale (1 at 122 px, two cells), the type and marks from it
    readonly property real s: K.Kit.clamp(Math.min(width, height) / 122, 0.85, 1.2)
    readonly property int titleSize: Math.round(14 * s)
    readonly property int artistSize: Math.round(12 * s)
    readonly property int timeSize: Math.round(10 * s)
    readonly property int play: 2 * Math.round(18 * s)
    readonly property int skip: 2 * Math.round(play * 0.4)
    readonly property int gap: Math.round(K.Kit.spacing.medium * Math.min(s, 1.2))

    MediaState {
        id: media
        active: root.visible
    }

    WheelHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: w => w.angleDelta.y < 0 ? MprisController.next() : MprisController.previous()
    }
    TapHandler {
        enabled: root.interactive
        acceptedButtons: Qt.RightButton
        onTapped: root.pickPlayer()
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({
                strip: strip,
                tall: tall,
                block: block
            })[root.layout] ?? wide
    }

    // ── the pieces ──

    // play / pause
    component PlayMark: Item {
        id: pm
        property int size: root.play
        readonly property bool filled: root.look !== "tone" && (root.shapes || media.playing)
        readonly property real radius: root.shapes && media.playing ? width / 2 : Math.round(width * 0.3)
        width: size
        height: size
        opacity: MprisController.canTogglePlaying || !root.interactive ? 1 : 0.38

        Rectangle {
            anchors.fill: parent
            visible: pm.filled
            radius: pm.radius
            color: root.accent
            Behavior on radius {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }
        }
        K.StateLayer {
            radius: pm.radius
            color: pm.filled ? root.overAccent : root.accent
            disabled: !root.interactive || !MprisController.canTogglePlaying
            onClicked: MprisController.togglePlaying()
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            text: media.playing ? "pause" : "play_arrow"
            fill: 1
            size: 2 * Math.round(pm.size * (pm.filled ? 0.25 : 0.32))
            color: pm.filled ? root.overAccent : root.accent
        }
    }

    // previous / next
    component SkipMark: Item {
        id: sm
        property string symbol: "skip_next"
        property int size: root.skip
        readonly property bool can: symbol === "skip_previous" ? MprisController.canGoPrevious : MprisController.canGoNext
        readonly property real radius: root.shapes ? Math.round(width * 0.3) : width / 2
        width: size
        height: size
        opacity: can || !root.interactive ? 1 : 0.38

        Rectangle {
            anchors.fill: parent
            visible: root.shapes
            radius: sm.radius
            color: root.pal.off
        }
        K.StateLayer {
            radius: sm.radius
            color: root.strong
            disabled: !root.interactive || !sm.can
            onClicked: sm.symbol === "skip_previous" ? MprisController.previous() : MprisController.next()
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            text: sm.symbol
            fill: 1
            size: 2 * Math.round(sm.size * (root.shapes ? 0.27 : 0.33))
            color: root.shapes ? root.pal.over : root.look === "tone" ? root.tone : root.weak
        }
    }

    // the progress (seeks); waving it thins to 4 px, as the sliders
    component Progress: K.M3Slider {
        readonly property bool waving: root.wavy && media.playing
        height: 16
        vertical: false
        trackThickness: waving ? 4 : root.look === "tones" ? 8 : root.look === "tone" ? 4 : 6
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
        valueIndicator: false
        interactive: root.interactive && media.canSeek
        value: media.progress
        onMoved: v => media.seek(v)
    }

    component Time: CapText {
        width: implicitWidth
        family: K.Kit.clockFamily
        pixelSize: root.timeSize
        weight: 500
        color: root.weak
    }

    // the times under the progress (block, tall)
    component Times: Item {
        visible: root.showTimes && media.length > 0
        height: root.timeSize + 2

        Time {
            anchors.left: parent.left
            height: parent.height
            text: media.time(media.position)
        }
        Time {
            anchors.right: parent.right
            height: parent.height
            text: media.time(media.length)
        }
    }

    // the controls: previous · play · next, the times at the ends when they fit (`times`)
    component Controls: Item {
        id: ctl
        property bool times: root.showTimes
        property bool skips: true
        property int size: root.play
        // the times only where they fit beside the buttons
        readonly property real rowWidth: size + (skips ? 2 * (2 * Math.round(size * 0.4) + Math.round(root.gap * 0.6)) : 0)
        readonly property bool showTimes: times && media.length > 0 && width >= rowWidth + 2 * (Math.ceil(root.timeSize * 2.4) + root.gap)
        height: size

        Time {
            visible: ctl.showTimes
            anchors.left: parent.left
            height: parent.height
            text: media.time(media.position)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(root.gap * 0.6)

            SkipMark {
                visible: ctl.skips
                anchors.verticalCenter: parent.verticalCenter
                symbol: "skip_previous"
                size: 2 * Math.round(ctl.size * 0.4)
            }
            PlayMark {
                size: ctl.size
            }
            SkipMark {
                visible: ctl.skips
                anchors.verticalCenter: parent.verticalCenter
                symbol: "skip_next"
                size: 2 * Math.round(ctl.size * 0.4)
            }
        }
        Time {
            visible: ctl.showTimes
            anchors.right: parent.right
            height: parent.height
            text: media.time(media.length)
        }
    }

    // the title (bold, strong) and the artist (weak)
    component Texts: Column {
        id: texts
        property int align: Text.AlignLeft
        spacing: Math.round(2 * root.s)

        CapText {
            width: parent.width
            height: root.titleSize + 4
            horizontalAlignment: texts.align
            family: K.Kit.family
            text: media.title
            pixelSize: root.titleSize
            weight: 700
            color: root.strong
        }
        CapText {
            width: parent.width
            height: root.artistSize + 4
            visible: media.artist !== ""
            horizontalAlignment: texts.align
            family: K.Kit.family
            text: media.artist
            pixelSize: root.artistSize
            weight: 500
            color: root.weak
        }
    }

    // the art: a rounded square, or (disc) a record turning while playing, in its wavy ring when big
    component ArtView: Item {
        id: av
        readonly property bool ring: root.disc && width >= 72

        K.WavyRing {
            anchors.fill: parent
            visible: av.ring
            value: media.progress
            wavy: root.wavy && media.playing
            thickness: 4
            amplitude: 2
            activeColor: root.accent
            inactiveColor: root.pal.track
            interactive: root.interactive && media.canSeek
            onMoved: v => media.seek(v)
        }
        Art {
            id: art
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: av.ring ? parent.width - 24 : parent.width
            height: width
            radius: root.disc ? width / 2 : Math.min(Math.round(width * 0.22), K.Kit.rounding.large)
            source: media.artUrl
            placeholder: root.shapes ? root.pal.off : Qt.alpha(root.tone, 0.15)
            note: root.weak
            // the picture turns inside the still disc (its rim stays smooth)
            NumberAnimation on spin {
                from: 0
                to: 360
                duration: 24000
                loops: Animation.Infinite
                running: root.disc && root.visible && K.Kit.anim.enabled
                paused: running && !media.playing
            }
        }
    }

    // ── the layouts ──

    // a row: art · title and artist (the progress under them when wide) · controls
    Component {
        id: strip
        Item {
            id: st
            readonly property bool roomy: width >= 240
            readonly property int size: 2 * Math.floor(Math.min(height, 36) / 2)

            ArtView {
                id: stArt
                visible: root.showArt
                width: 2 * Math.floor(Math.min(st.height, 44) / 2)
                height: width
                y: Math.round((st.height - height) / 2)
            }
            Controls {
                id: stCtl
                anchors.right: parent.right
                y: Math.round((st.height - height) / 2)
                width: st.roomy ? st.size + 2 * (2 * Math.round(st.size * 0.4) + Math.round(root.gap * 0.6)) : st.size
                size: st.size
                skips: st.roomy
                times: false
            }
            Column {
                x: stArt.visible ? stArt.width + root.gap : 0
                y: Math.round((st.height - height) / 2)
                width: stCtl.x - x - root.gap
                spacing: 2

                Texts {
                    width: parent.width
                }
                Progress {
                    visible: st.width >= 300 && !stArt.ring
                    width: parent.width
                    height: 10
                }
            }
        }
    }

    // the art at the left (at most 45 % of the width), the texts, progress and controls beside it
    Component {
        id: wide
        Item {
            id: wd
            readonly property int art: 2 * Math.floor(Math.min(height, width * 0.45) / 2)

            ArtView {
                id: wdArt
                visible: root.showArt
                width: wd.art
                height: wd.art
                y: Math.round((wd.height - height) / 2)
            }
            Column {
                x: wdArt.visible ? wdArt.width + Math.round(root.gap * 1.4) : 0
                y: Math.round((wd.height - height) / 2)
                width: wd.width - x
                spacing: Math.round(4 * root.s)

                Texts {
                    width: parent.width
                }
                Progress {
                    visible: !wdArt.ring || !wdArt.visible
                    width: parent.width
                }
                Controls {
                    width: parent.width
                }
            }
        }
    }

    // about square (2x2 … 5x4, 3x2, 4x3): the art as big as the height leaves, prev · play · next in a row
    // beside it when they fit, else play alone (bigger; the wheel skips), the texts, progress and times
    // under them. Without the art, the controls row sits over the texts.
    Component {
        id: block
        Item {
            id: bk
            readonly property int gapY: Math.round(8 * root.s)
            readonly property bool timesRow: root.showTimes && media.length > 0 && height >= 170
            readonly property int textHeight: root.titleSize + 4 + (media.artist !== "" ? root.artistSize + 4 + bkTexts.spacing : 0)
            readonly property int bottomHeight: textHeight + 4 + 16 + (timesRow ? root.timeSize + 4 : 0)
            // the top row's height (the art's, at most)
            readonly property int topHeight: height - bottomHeight - gapY
            readonly property int spacing: Math.round(root.gap * 0.6)
            readonly property int play: 2 * Math.round(K.Kit.clamp(Math.min(topHeight * 0.34, width * 0.18), 30, 48) / 2)
            readonly property int skip: 2 * Math.round(play * 0.4)
            // prev · play · next, always side by side (user: never a column)
            readonly property int span: play + 2 * (skip + spacing)
            // the art keeps its full size (user: drop controls rather than shrink it): prev / next go
            // when the row doesn't fit beside it, play stays alone (bigger); the wheel still skips
            readonly property bool hasArt: root.showArt && topHeight >= 28
            readonly property int art: hasArt ? 2 * Math.floor(Math.min(topHeight, width - play - root.gap) / 2) : 0
            readonly property int side: hasArt ? width - art - root.gap : width
            readonly property bool row: side >= span
            readonly property int alonePlay: 2 * Math.round(K.Kit.clamp(Math.min(side, topHeight * 0.45), 30, 56) / 2)

            Column {
                width: parent.width
                y: Math.round((bk.height - height) / 2)
                spacing: bk.gapY

                Item {
                    width: parent.width
                    height: bk.hasArt ? bk.art : bk.play

                    ArtView {
                        id: bkArt
                        visible: bk.hasArt
                        width: bk.art
                        height: bk.art
                    }
                    Item {
                        x: bk.hasArt ? bk.art + root.gap : 0
                        width: bk.side
                        height: parent.height

                        Row {
                            visible: bk.row
                            anchors.centerIn: parent
                            spacing: bk.spacing
                            SkipMark {
                                anchors.verticalCenter: parent.verticalCenter
                                symbol: "skip_previous"
                                size: bk.skip
                            }
                            PlayMark {
                                size: bk.play
                            }
                            SkipMark {
                                anchors.verticalCenter: parent.verticalCenter
                                symbol: "skip_next"
                                size: bk.skip
                            }
                        }
                        PlayMark {
                            visible: !bk.row
                            anchors.centerIn: parent
                            size: bk.alonePlay
                        }
                    }
                }
                Column {
                    width: parent.width
                    spacing: 4

                    Texts {
                        id: bkTexts
                        width: parent.width
                    }
                    Column {
                        width: parent.width
                        spacing: 2
                        Progress {
                            visible: !bkArt.ring || !bkArt.visible
                            width: parent.width
                        }
                        Times {
                            visible: bk.timesRow
                            width: parent.width
                        }
                    }
                }
            }
        }
    }

    // the art on top (what's left of the height, at most the width), the rest centred under it
    Component {
        id: tall
        Item {
            id: tl
            readonly property real rest: (root.titleSize + root.artistSize + 10) + (root.disc ? 0 : 16) + root.timeSize + 4 + root.play + 3 * spacingY
            readonly property int spacingY: Math.round(6 * root.s)
            readonly property int art: 2 * Math.floor(Math.min(width, height - rest - spacingY) / 2)

            Column {
                width: parent.width
                y: Math.round((tl.height - height) / 2)
                spacing: tl.spacingY

                ArtView {
                    id: artBox
                    visible: root.showArt && tl.art >= 48
                    width: tl.art
                    height: tl.art
                    x: Math.round((parent.width - width) / 2)
                }
                Texts {
                    width: parent.width
                    align: Text.AlignHCenter
                }
                Column {
                    width: parent.width
                    spacing: 2
                    Progress {
                        visible: !artBox.ring || !artBox.visible
                        width: parent.width
                    }
                    Times {
                        width: parent.width
                    }
                }
                Controls {
                    width: parent.width
                    times: false
                }
            }
        }
    }
}
