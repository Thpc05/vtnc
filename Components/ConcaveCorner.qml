import QtQuick

// ═══════════════════════════════════════════
//  CONCAVE CORNER — um quarto de curva que "solda" duas superfícies
//  perpendiculares: preenche o cantinho entre elas com a curva
//  olhando pra fora. É a peça dos cantos da tela.
//
//  Desenhado como TOP-LEFT (massa no canto superior-esquerdo, curva
//  olhando pro bottom-right). Use `rotation` pros outros cantos:
//   0 = top-left · 90 = top-right · 180 = bottom-right · 270 = bottom-left
// ═══════════════════════════════════════════
Canvas {
    id: root

    property real radius: 16
    property color fillColor: Theme.bg

    width: radius
    height: radius
    // Abaixo de 1px não há curva pra desenhar, só sub-pixel borrado
    visible: radius >= 1

    // ARMADILHA do Canvas: ele NÃO repinta sozinho quando só o
    // tamanho muda — estica o buffer antigo (um raio de 1px vira um
    // quadrado borrado de 10px). E não pinta enquanto invisível, o
    // que faz aparecer lixo do tamanho anterior ao voltar. Repintar
    // em TODA mudança de geometria/visibilidade é o que segura isso.
    onRadiusChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onFillColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (radius <= 0)
            return
        ctx.fillStyle = root.fillColor
        ctx.beginPath()
        // Massa entre o vértice e o arco (centro em r,r)
        ctx.moveTo(0, 0)
        ctx.lineTo(radius, 0)
        ctx.arc(radius, radius, radius, -Math.PI / 2, Math.PI, true)
        ctx.lineTo(0, 0)
        ctx.fill()
    }
}
