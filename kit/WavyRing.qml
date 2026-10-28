import QtQuick
import QtQuick.Shapes

// A circular progress from the top, clockwise: the played arc wavy while `wavy` (the wave runs),
// the rest a plain arc, with a gap between them (M3 Expressive's wavy circular indicator).
// A click / drag on the ring seeks (`moved`).
Item {
    id: root

    property real value: 0
    property bool wavy: false
    property real thickness: 4
    property int waves: 12
    property real amplitude: 2.5
    property color activeColor
    property color inactiveColor
    property bool interactive: false
    signal moved(real value)

    // the wave's height, easing to flat when it stops
    property real wave: wavy ? amplitude : 0
    Behavior on wave {
        Anim {
            type: Anim.DefaultEffects
        }
    }
    property real phase: 0
    NumberAnimation on phase {
        from: 0
        to: 2 * Math.PI
        duration: 2000
        loops: Animation.Infinite
        running: root.wavy && root.visible && Kit.anim.enabled
    }

    readonly property real r: Math.min(width, height) / 2 - thickness / 2 - amplitude
    readonly property real gap: r > 0 ? (thickness + 6) / (2 * Math.PI * r) : 0
    readonly property real shown: Kit.clamp(value, 0, 1)

    function arc(a: real, b: real, wavy: bool): var {
        const out = [];
        if (b <= a)
            return out;
        const n = Math.max(2, Math.ceil((b - a) * 240));
        for (let i = 0; i <= n; i++) {
            const t = a + (b - a) * i / n;
            const th = -Math.PI / 2 + t * 2 * Math.PI;
            const rr = r + (wavy ? root.wave * Math.sin(root.waves * th * 1 + root.phase) : 0);
            out.push(Qt.point(width / 2 + rr * Math.cos(th), height / 2 + rr * Math.sin(th)));
        }
        return out;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: rest
            fillColor: "transparent"
            strokeColor: root.inactiveColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            // an exact arc, not a polyline: the CurveRenderer drew the tiny ring's many short segments as
            // a stray dot on the GPU (the battery's ring)
            readonly property real from: root.shown > 0.002 ? root.shown + root.gap : 0
            readonly property real to: root.shown > 0.002 ? 1 - root.gap : 1
            startX: root.width / 2 + root.r * Math.cos(-Math.PI / 2 + from * 2 * Math.PI)
            startY: root.height / 2 + root.r * Math.sin(-Math.PI / 2 + from * 2 * Math.PI)
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: -90 + rest.from * 360
                sweepAngle: Math.max(0, rest.to - rest.from) * 360
            }
        }
        ShapePath {
            fillColor: "transparent"
            // nothing at 0 (its round cap would still draw a dot)
            strokeColor: root.shown > 0 ? root.activeColor : "transparent"
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathPolyline {
                // never an empty list ("PathPolyline: path of type 0 not supported" while the value
                // animates up from 0)
                path: root.shown > 0 ? root.arc(0, root.shown, true) : [Qt.point(0, 0), Qt.point(0, 0)]
            }
        }
    }

    // seek on the ring band only
    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        function seekAt(x: real, y: real) {
            const dx = x - width / 2;
            const dy = y - height / 2;
            let a = Math.atan2(dy, dx) + Math.PI / 2;
            if (a < 0)
                a += 2 * Math.PI;
            root.moved(a / (2 * Math.PI));
        }
        function onBand(x: real, y: real): bool {
            const d = Math.hypot(x - width / 2, y - height / 2);
            return Math.abs(d - root.r) <= root.thickness + root.amplitude + 6;
        }
        onPressed: m => {
            if (!onBand(m.x, m.y)) {
                m.accepted = false;
                return;
            }
            seekAt(m.x, m.y);
        }
        onPositionChanged: m => {
            if (pressed)
                seekAt(m.x, m.y);
        }
    }
}
