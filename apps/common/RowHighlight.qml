import QtQuick
import qs.dwidgets.quick.panels
import qs.kit as K

// A list's current row in the apps' look (2026-10-17; a ListView `highlight`): Shapes the container and
// the FocusShape behind the row's icon, Two tones the container tinted with the primary, Tone no fill
// and a bar at its left. `rowHeight` is the row's own part (a grown row keeps its mark there), `iconX`
// the icon's centre.
Rectangle {
    id: root

    required property PanelColors c
    property FocusShape focusShape: null
    property int rowHeight: 48
    property real iconX: 24
    property int shapeSize: 44

    // Two tones: the container tinted with the primary (a plain alpha on the page read grey in light)
    readonly property color tint: Qt.tint(K.Kit.expressive.container, Qt.alpha(c.accent, K.Kit.expressive.light ? 0.16 : 0.12))

    radius: K.Kit.rounding.large
    color: c.shapes ? K.Kit.expressive.container : c.kind === "tones" ? tint : "transparent"

    K.M3Shape {
        visible: root.c.shapes && root.focusShape !== null
        x: Math.round(root.iconX - width / 2)
        y: Math.round((root.rowHeight - height) / 2)
        width: root.shapeSize
        height: root.shapeSize
        samples: 60
        animate: !(root.focusShape?.instant ?? false)
        shape: root.focusShape?.shape || "cookie7"
        color: root.c.accent
    }

    Rectangle {
        visible: root.c.kind === "tone"
        x: 0
        y: Math.round((root.rowHeight - height) / 2)
        width: 3
        height: 20
        radius: 1.5
        color: root.c.accent
    }
}
