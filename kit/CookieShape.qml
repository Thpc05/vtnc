import QtQuick
import QtQuick.Shapes
import qs.theme

// A scalloped circle, like M3 Expressive's cookie / sunny shapes: the radius swings `depth` (a
// fraction of it) over `sides` lobes, r(θ) = R·(1 − depth·(1 − cos(sides·(θ − turn)))/2). 9 sides with
// a soft depth is the cookie, 12 with a shallow one the sunny. Filled with `color`, or with
// `fillItem` (a cover image) clipped to the shape.
// vtnc: our own path, so no M3Shapes dependency.
Shape {
    id: root

    property int sides: 9
    property real depth: 0.12
    // rotates the lobes, in degrees
    property real turn: 0
    property color color: Colors.primary
    // an Item to fill the shape with instead of `color` (a cover image), stretched to the shape
    property Item fillItem: null
    // path points (more = smoother)
    property int samples: 144

    readonly property real radius: Math.min(width, height) / 2

    // the outline's distance from the centre at `deg` degrees (0 = right, clockwise)
    function distanceAtAngle(deg: real): real {
        const t = (deg - turn) * Math.PI / 180;
        return radius * (1 - depth * (1 - Math.cos(sides * t)) / 2);
    }

    readonly property var outline: {
        const pts = [];
        const cx = width / 2;
        const cy = height / 2;
        for (let i = 0; i <= samples; i++) {
            const deg = i * 360 / samples;
            const r = distanceAtAngle(deg);
            const a = deg * Math.PI / 180;
            pts.push(Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)));
        }
        return pts;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillItem ? "transparent" : root.color
        fillItem: root.fillItem

        PathPolyline {
            path: root.outline
        }
    }
}
