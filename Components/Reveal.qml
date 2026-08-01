import QtQuick

// ═══════════════════════════════════════════
//  REVEAL — Contrato de um hover-reveal da pill wide.
//  O PRÓPRIO item é o anchor (um ícone no cluster da barra); `panel`
//  é o conteúdo que a Bar hospeda abaixo da linha principal e revela
//  ao mirar o anchor.
//
//  Mesmo padrão Pill ↔ PillFace, um nível abaixo: a Bar não conhece
//  nenhum reveal concreto, só este contrato.
//
//  Contrato:
//   - o anchor são os filhos visuais deste item
//   - `panel` deve ter implicitHeight e um `Behavior on opacity`
//     (a Bar dirige o fade)
//   - o arquivo concreto liga `panelHovered` ao HoverHandler do
//     próprio painel (mirar o painel segura ele aberto)
// ═══════════════════════════════════════════
Item {
    id: reveal

    property string name: ""

    // Conteúdo revelado (reparentado pelo host)
    property Item panel: null
    // Altura que o host cresce quando revelado
    property real panelHeight: panel ? panel.implicitHeight : 0

    // Largura NATURAL do painel. Usada por hosts que NÃO esticam — a
    // bolha da framed sai nesta largura. Hosts que esticam (a pill, que
    // hospeda o painel full-width) ignoram. 0 = deixa o host decidir.
    property real panelWidth: 0

    // Mirado dentro do painel — setado pelo reveal concreto
    property bool panelHovered: false

    // O reveal se abre SOZINHO, sem ninguém mirar (ex: notificação
    // chegando). Quem hospeda trata como mira — mas sem esperar os
    // reveals armarem: isto é explícito, não é o mouse passeando.
    property bool autoShow: false

    // Mirado (cru): a Bar aplica o grace period antes de fechar
    readonly property bool revealed: anchorHover.hovered || panelHovered || autoShow

    width: childrenRect.width
    height: childrenRect.height

    HoverHandler {
        id: anchorHover
        margin: 6 // ícones são pequenos; folga no alvo
    }
}
