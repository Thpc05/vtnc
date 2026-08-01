pragma Singleton
import QtQuick
import ".."
import "../Pill"

// ═══════════════════════════════════════════
//  FRAMED THEME — Estética só da barra de topo.
//  A framed é uma camada independente POR BAIXO da pill; nada aqui é
//  lido pela pill nem pelos apps.
// ═══════════════════════════════════════════
QtObject {
    // Respiro abaixo da pill DENTRO da barra (o "framedMarginDown").
    // A barra engloba a pegada da pill (marginTop + height + marginDown)
    // e ainda desce este tanto
    readonly property real marginDown: 6

    // Altura total da faixa. É também o que a janela de reserva
    // (exclusivezone) reserva quando a framed está ligada
    readonly property real height:
        Pill_Theme.marginTop + Pill_Theme.height + Pill_Theme.marginDown + marginDown

    readonly property color barColor: Theme.bg

    // Cantos CÔNCAVOS da base da barra (onde ela encontra as laterais
    // da tela e curva pra dentro — o visual caelestia). Mesmo raio dos
    // cantos da tela
    readonly property real cornerRadius: Math.abs(Theme.screenCornerRadius)

    // Onde os widgets encostam nas pontas da barra
    readonly property real contentMargin: 14

    // ── BOLHA (o painel que emerge da barra ao mirar um widget) ──
    readonly property real bubbleRadius: 18
    readonly property real bubblePad: 10
    // Raio da SOLDA (cantos côncavos entre a bolha e a barra — o
    // "welding" caelestia: a bolha parece brotar da faixa)
    readonly property real weldRadius: 14
    // Grace pro mouse cruzar do widget até a bolha sem ela fechar
    readonly property int bubbleGrace: 250
}
