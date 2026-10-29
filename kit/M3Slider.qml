import QtQuick
import QtQuick.Shapes
import qs.theme

// The M3 Expressive slider (the `expressive` style): an active track, then a gap, a thin handle
// across the track (taller than it), a gap, and the inactive track with a stop dot at its end.
// Horizontal (active on the left) or vertical (active at the bottom). An optional `icon` sits
// inside the active track at its start; the handle never goes over it.
// Options:
//   wavy            the active track is a sine wave (M3's wavy slider), moving while `animateWave`
//   handleShape     "bar" (the thin handle) or "circle" (a round thumb, as the wavy sliders use)
//   valueIndicator  a bubble with the percent above the handle while it's pressed
// Input is SliderInput; `moved` fires on user input only, and a click on the icon emits
// `iconClicked` (mute, sync…).
Item {
    id: root

    property real value: 0
    property bool vertical: height > width
    // the track's thickness; the handle spans the whole cross size
    property real trackThickness: Math.round(cross * 0.5)
    property string icon: ""
    property real iconFill: 1
    property bool muted: false
    property bool interactive: true

    property bool wavy: false
    property bool animateWave: true
    property real waveAmplitude: 3
    property real wavelength: 22
    property string handleShape: wavy ? "circle" : "bar"
    property bool valueIndicator: false
    // the inactive track's thickness (thinner under a wave)
    property real inactiveThickness: trackThickness

    property color activeColor: Kit.expressive.track
    property color inactiveColor: Kit.expressive.inactiveTrack

    readonly property bool dragging: input.dragging
    readonly property bool pressed: input.pressed
    signal moved(real value)
    signal iconClicked

    readonly property real cross: vertical ? width : height
    readonly property real length: vertical ? height : width
    readonly property bool circle: handleShape === "circle"
    readonly property bool waving: wavy
    // the space between the bar handle and the tracks
    property int handleGap: 4
    readonly property int gap: circle ? 0 : handleGap
    // the thumb's diameter when round
    readonly property real thumbSize: Math.min(cross, Math.max(trackThickness * 3, 14))
    readonly property real handleWidth: circle ? thumbSize : pressed ? 2 : 4
    readonly property real handleHalf: circle ? thumbSize / 2 : 2
    // the handle's centre along the track; with an icon, 0 sits just past it, so the icon always
    // stays inside the active track
    readonly property real minAt: icon !== "" ? trackThickness + gap + handleHalf : handleHalf
    readonly property real handleAt: minAt + (length - minAt - handleHalf) * Kit.clamp(shown, 0, 1)
    readonly property real outer: trackThickness / 2
    readonly property int inner: 2

    // follows `value`, animated unless it's being dragged
    property real shown: value
    Behavior on shown {
        enabled: !root.dragging
        Anim {
            type: Anim.DefaultEffects
        }
    }

    // the active track: round at the start, tight next to the handle
    Rectangle {
        id: active
        readonly property real end: root.handleAt - root.handleWidth / 2 - root.gap
        visible: end > 1 && !root.waving
        color: root.muted ? Qt.alpha(root.activeColor, 0.38) : root.activeColor
        topLeftRadius: root.vertical ? root.inner : Math.min(root.outer, width / 2)
        bottomLeftRadius: Math.min(root.outer, root.vertical ? height / 2 : width / 2)
        bottomRightRadius: root.vertical ? Math.min(root.outer, height / 2) : root.inner
        topRightRadius: root.inner
        x: root.vertical ? (root.width - root.trackThickness) / 2 : 0
        y: root.vertical ? root.height - height : (root.height - root.trackThickness) / 2
        width: root.vertical ? root.trackThickness : Math.max(0, end)
        height: root.vertical ? Math.max(0, end) : root.trackThickness

        Behavior on color {
            CAnim {}
        }
    }

    // the inactive track: tight next to the handle, round at the end, with the stop dot
    Rectangle {
        id: inactive
        readonly property real start: root.handleAt + root.handleWidth / 2 + root.gap
        visible: root.length - start > 1
        color: root.inactiveColor
        readonly property real o: t / 2
        topLeftRadius: root.vertical ? Math.min(o, height / 2) : root.circle ? o : root.inner
        topRightRadius: Math.min(o, root.vertical ? height / 2 : width / 2)
        bottomRightRadius: root.vertical ? (root.circle ? o : root.inner) : Math.min(o, width / 2)
        bottomLeftRadius: root.circle ? o : root.inner
        readonly property real t: root.inactiveThickness
        x: root.vertical ? (root.width - t) / 2 : start
        y: root.vertical ? 0 : (root.height - t) / 2
        width: root.vertical ? t : Math.max(0, root.length - start)
        height: root.vertical ? Math.max(0, root.length - start) : t

        Rectangle {
            readonly property real size: Math.max(4, Math.round(root.inactiveThickness / 5))
            width: size
            height: size
            radius: size / 2
            x: root.vertical ? (parent.width - size) / 2 : parent.width - parent.t / 2 - size / 2
            y: root.vertical ? parent.t / 2 - size / 2 : (parent.height - size) / 2
            visible: parent.width > size * 3 && parent.height > size * 3 && root.inactiveThickness >= 8
            color: root.activeColor
        }
    }

    // the wavy active track: a sine from the start to the handle, drifting while animateWave (still when
    // the shell's animations are off)
    property real phase: 0
    NumberAnimation on phase {
        running: root.waving && root.animateWave && Kit.anim.enabled && root.visible && !root.muted
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }
    Shape {
        anchors.fill: parent
        visible: root.waving && active.end > root.trackThickness
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.trackThickness
            strokeColor: active.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: {
                    const pts = [];
                    const t = root.trackThickness / 2;
                    const a0 = t;
                    const a1 = Math.max(a0, active.end - t);
                    const k = Math.PI * 2 / root.wavelength;
                    const c = root.cross / 2;
                    // along the track from its start (left / bottom)
                    const at = (d, w) => root.vertical ? Qt.point(c + w, root.height - d) : Qt.point(d, c + w);
                    for (let d = a0; d <= a1; d += 2)
                        pts.push(at(d, root.waveAmplitude * Math.sin(k * d - root.phase)));
                    pts.push(at(a1, root.waveAmplitude * Math.sin(k * a1 - root.phase)));
                    return pts;
                }
            }
        }
    }

    // the handle: a thin bar across the track, or a round thumb
    Rectangle {
        id: handle
        radius: Math.min(width, height) / 2
        color: root.muted ? Qt.alpha(root.activeColor, 0.6) : root.activeColor
        x: root.vertical ? (root.width - width) / 2 : root.handleAt - width / 2
        y: root.vertical ? root.height - root.handleAt - height / 2 : (root.height - height) / 2
        width: root.vertical ? (root.circle ? root.thumbSize : root.width) : root.handleWidth
        height: root.vertical ? root.handleWidth : (root.circle ? root.thumbSize : root.height)
        scale: root.circle && root.pressed ? 1.15 : 1

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on width {
            enabled: !root.vertical
            Anim {
                type: Anim.FastSpatial
            }
        }
        Behavior on height {
            enabled: root.vertical
            Anim {
                type: Anim.FastSpatial
            }
        }
    }

    // the value bubble above the handle while it's pressed
    Rectangle {
        visible: root.valueIndicator
        width: Math.max(36, bubble.implicitWidth + 16)
        height: 28
        radius: height / 2
        color: Colors.overSurface
        x: root.vertical ? -width - 6 : root.handleAt - width / 2
        y: root.vertical ? root.height - root.handleAt - height / 2 : (root.height - root.cross) / 2 - height - 6
        opacity: root.pressed ? 1 : 0
        scale: root.pressed ? 1 : 0.6
        transformOrigin: root.vertical ? Item.Right : Item.Bottom

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        StyledText {
            id: bubble
            anchors.centerIn: parent
            text: Math.round(Kit.clamp(root.value, 0, 1) * 100)
            font: Kit.font.label.large
            color: Colors.surface
        }
    }

    // the icon at the track's start
    Item {
        id: iconCell
        readonly property real size: root.trackThickness
        readonly property bool onActive: active.visible
        visible: root.icon !== ""
        width: size
        height: size
        x: root.vertical ? (root.width - size) / 2 : 0
        y: root.vertical ? root.height - size : (root.height - size) / 2

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: root.icon
            fontStyle: root.trackThickness >= 32 ? Kit.font.icon.medium : Kit.font.icon.small
            fill: root.iconFill
            color: iconCell.onActive && !root.muted ? Colors.overPrimary : Colors.overSecondaryContainer
        }
    }

    SliderInput {
        id: input
        anchors.fill: parent
        enabled: root.interactive
        vertical: root.vertical
        value: root.value
        startOffset: root.minAt
        span: root.length - root.minAt - root.handleHalf
        iconItem: root.icon !== "" ? iconCell : null
        onMoved: v => root.moved(v)
        onIconClicked: root.iconClicked()
    }
}
