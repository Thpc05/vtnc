import QtQuick
import ".."
import "../../../Config"
import "../../../Ui"

// ═══════════════════════════════════════════
//  SLIDER CARD — O slider do Control Center: o card INTEIRO é a
//  barra, e o ícone mora dentro dela, à esquerda.
//
//  Diferente de um slider comum de propósito: sem trilho fino e sem
//  polegar. O preenchimento é a própria superfície do card, então o
//  alvo é a área toda — não uma linha de 6px.
//
//  `value` é 0→1 e é BINDING de leitura; arrastar chama `commit`, e o
//  preenchimento só anda quando a fonte confirma. Mesma regra dos
//  controles do config app: uma cópia local daria duas verdades.
// ═══════════════════════════════════════════
DashCard {
    id: root

    property string icon: ""
    property real value: 0
    // Só o ícone muda quando mudo; o valor continua o que era
    property bool muted: false

    signal commit(real v)

    // O card do slider não acende inteiro: quem mostra o nível é o
    // preenchimento
    lit: false
    color: Theme.card

    function _apply(px) {
        root.commit(Math.max(0, Math.min(1, px / root.width)))
    }

    // ── PREENCHIMENTO ──
    // Vive FORA do host de conteúdo (que tem margem): ele precisa
    // encostar nas bordas do card. z negativo pra ficar sob o ícone
    Rectangle {
        z: -1
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, root.value))
        color: root.muted ? Theme.textMuted : Theme.accent
        Behavior on color { ColorAnimation { duration: Motion.instant } }
        // Sem Behavior na largura: arrastar tem que colar no cursor.
        // Um Behavior aqui faria a barra perseguir o dedo com atraso
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        // Sobre o preenchimento accent o ícone é preto; no trecho
        // vazio, claro. Como ele fica na ponta esquerda, o que vale é
        // se o preenchimento já passou dele
        color: root.value > 0.08 && !root.muted ? Theme.bg : Theme.textPrimary
        font { family: Theme.fontIcon; pixelSize: 17 }
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    MouseArea {
        anchors.fill: parent
        // O chevron do detalhe fica de fora: ele tem alvo próprio
        anchors.rightMargin: root.detail !== "" ? 30 : 0
        onPressed: mouse => root._apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) root._apply(mouse.x) }
    }
}
