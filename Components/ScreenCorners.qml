import QtQuick

// ═══════════════════════════════════════════
//  SCREEN CORNERS — Cantos da tela.
//  Item puro, não-interativo: fica fora da mask, então nunca
//  intercepta cliques.
//
//  Theme.screenCornerRadius aceita NEGATIVO:
//   > 0  o canto é RECORTADO — a massa preta fica entre o vértice e
//        o arco, "fechando" o canto (o padrão).
//   < 0  a curva INVERTE — a massa vira um quarto de disco que
//        avança pra dentro da tela: é o visual "framed".
//   = 0  desliga.
// ═══════════════════════════════════════════
Item {
    id: root

    readonly property real r: Math.abs(Theme.screenCornerRadius)
    readonly property bool framed: Theme.screenCornerRadius < 0

    component Corner: ConcaveCorner {
        radius: root.r
        framed: root.framed
        fillColor: Theme.screenCornerColor
    }

    Corner { anchors.top: parent.top; anchors.left: parent.left }
    Corner { anchors.top: parent.top; anchors.right: parent.right; rotation: 90 }
    Corner { anchors.bottom: parent.bottom; anchors.right: parent.right; rotation: 180 }
    Corner { anchors.bottom: parent.bottom; anchors.left: parent.left; rotation: 270 }
}
