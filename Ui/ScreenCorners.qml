import QtQuick
import "../Config"

// ═══════════════════════════════════════════
//  SCREEN CORNERS — Cantos da tela.
//  Item puro, não-interativo: fica fora da mask, então nunca
//  intercepta cliques.
//
//  Theme.radiusScreen recorta o canto: a massa preta fica
//  entre o vértice e o arco, "fechando" o canto. 0 desliga.
// ═══════════════════════════════════════════
Item {
    id: root

    readonly property real r: Math.max(0, Theme.radiusScreen)

    component Corner: ConcaveCorner {
        radius: root.r
        fillColor: Theme.screenCornerColor
    }

    Corner { anchors.top: parent.top; anchors.left: parent.left }
    Corner { anchors.top: parent.top; anchors.right: parent.right; rotation: 90 }
    Corner { anchors.bottom: parent.bottom; anchors.right: parent.right; rotation: 180 }
    Corner { anchors.bottom: parent.bottom; anchors.left: parent.left; rotation: 270 }
}
