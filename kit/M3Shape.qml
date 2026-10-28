import QtQuick
import QtQuick.Shapes
import qs.theme

// M3 Expressive's shape library, our own (vtnc: no M3Shapes dependency): each shape is a polar
// outline r(θ), sampled at the same angles, so changing `shape` morphs between them by
// interpolating the radii (caelestia's MaterialShape does this with M3Shapes' C++ morph).
// Shapes: circle, square (a rounded square), cookie4 / cookie6 / cookie7 / cookie9 / cookie12
// (scalloped), sunny (8 soft points), softBurst (10 points), clover4 / clover8 (deep lobes),
// pill (a rounded square stretched to the item). Filled with `color`, or with `fillItem` (an
// image) clipped to the shape. `turn` rotates it (degrees).
Shape {
    id: root

    property string shape: "circle"
    property color color: Colors.primary
    property Item fillItem: null
    property real turn: 0
    property int samples: 120
    // morph on `shape` changes
    property bool animate: true
    // a gentle morph (2026-10-27, the dashboard visualizer's beats): slower, no overshoot
    property bool gentle: false

    // the outline's radii (0…1 of the half size) for `name`, one per sample angle
    function radii(name: string): var {
        const out = [];
        let max = 0;
        for (let i = 0; i < samples; i++) {
            const t = i / samples * 2 * Math.PI;
            const r = radiusAt(name, t);
            out.push(r);
            max = Math.max(max, r);
        }
        return out.map(r => r / max);
    }

    function lobes(t: real, n: int, depth: real): real {
        return 1 - depth * (1 - Math.cos(n * t)) / 2;
    }
    // a superellipse (a squircle at n ≈ 5): |x|^n + |y|^n = 1
    function squircle(t: real, n: real): real {
        return 1 / Math.pow(Math.pow(Math.abs(Math.cos(t)), n) + Math.pow(Math.abs(Math.sin(t)), n), 1 / n);
    }

    function radiusAt(name: string, t: real): real {
        switch (name) {
        case "square":
        case "pill":
            return squircle(t, 5);
        case "cookie4":
            return lobes(t + Math.PI / 4, 4, 0.18);
        case "cookie6":
            return lobes(t, 6, 0.14);
        case "cookie7":
            return lobes(t, 7, 0.13);
        case "cookie9":
            return lobes(t, 9, 0.12);
        case "cookie12":
            return lobes(t, 12, 0.08);
        case "sunny":
            // soft points: a lobe raised to a power sharpens its crest
            return 1 - 0.14 * (1 - Math.pow((1 + Math.cos(8 * t)) / 2, 1.6));
        case "softBurst":
            return 1 - 0.2 * (1 - Math.pow((1 + Math.cos(10 * t)) / 2, 1.4));
        case "clover4":
            return lobes(t + Math.PI / 4, 4, 0.36);
        case "clover8":
            return lobes(t, 8, 0.26);
        default:
            return 1;
        }
    }

    // the morph: from the last outline to the new one
    property var fromRadii: radii(shape)
    property var toRadii: fromRadii
    property real progress: 1

    onShapeChanged: {
        const current = currentRadii();
        fromRadii = current;
        toRadii = radii(shape);
        if (animate && Kit.anim.enabled) {
            progress = 0;
            morph.restart();
        } else {
            progress = 1;
        }
    }
    onSamplesChanged: {
        fromRadii = radii(shape);
        toRadii = fromRadii;
    }

    function currentRadii(): var {
        const p = progress;
        return toRadii.map((r, i) => (fromRadii[i] ?? r) + (r - (fromRadii[i] ?? r)) * p);
    }

    readonly property var outline: {
        const rs = currentRadii();
        const pts = [];
        const cx = width / 2;
        const cy = height / 2;
        // a pill stretches to the item; the others stay round in a square
        const rx = shape === "pill" ? width / 2 : Math.min(width, height) / 2;
        const ry = shape === "pill" ? height / 2 : Math.min(width, height) / 2;
        const turnRad = turn * Math.PI / 180;
        for (let i = 0; i <= rs.length; i++) {
            const r = rs[i % rs.length];
            const a = i / rs.length * 2 * Math.PI + turnRad;
            pts.push(Qt.point(cx + r * rx * Math.cos(a), cy + r * ry * Math.sin(a)));
        }
        return pts;
    }

    preferredRendererType: Shape.CurveRenderer

    NumberAnimation {
        id: morph

        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.gentle ? 600 : Kit.anim.durations.expressiveFastSpatial
        easing.type: root.gentle ? Easing.InOutSine : Easing.BezierSpline
        easing.bezierCurve: Kit.anim.expressiveFastSpatial
    }

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillItem ? "transparent" : root.color
        fillItem: root.fillItem

        PathPolyline {
            path: root.outline
        }

        Behavior on fillColor {
            CAnim {}
        }
    }
}
