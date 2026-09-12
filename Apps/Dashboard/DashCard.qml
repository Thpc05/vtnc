import QtQuick
import "../../Config"
import "../../Ui"

// ═══════════════════════════════════════════
//  DASH CARD — A casca de um card do Control Center.
//
//  Substituiu o DashWidget, e o que ele perdeu é o ponto: não existe
//  mais `expanded`, `sizeIdle/sizeExpand`, `expandDir`, `gridCol/Row`,
//  drag nem pin. Card tem TAMANHO FIXO e posição declarada no
//  Dashboard.qml — quem quer ver mais abre o detalhe.
//
//  O CARD NÃO ACENDE INTEIRO. A primeira versão pintava o card todo de
//  accent quando ligado, e o resultado foi um bloco de cor gritando no
//  meio de uma shell preta. Quem acende é o ÍCONE (ver ToggleCard): o
//  card continua escuro e o estado mora num círculo de 34px. O
//  contraste fica no lugar certo e a superfície continua calma.
//
//  A BORDA de 1px é o detalhe que parece não fazer diferença e faz:
//  sem ela o card derrete no fundo preto; com ela ele tem aresta sem
//  virar contorno desenhado.
// ═══════════════════════════════════════════
Rectangle {
    id: card

    // Abre o detalhe (lista de redes, dispositivos, saídas de áudio).
    // Vazio = o card não tem detalhe e nem mostra o chevron
    property string detail: ""

    signal tapped()
    signal detailRequested(string nome)

    default property alias content: host.data

    readonly property bool hovered: mira.hovered

    radius: Theme.radiusCard
    color: Theme.card
    border.width: Theme.borderWidth
    border.color: Theme.border
    clip: true

    HoverHandler { id: mira }

    // A mira é uma CAMADA por cima, não uma segunda cor de fundo:
    // assim ela soma sobre qualquer coisa que o card esteja mostrando
    // (inclusive a capa borrada do MediaCard)
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: card.hovered ? Theme.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: card.tapped()
    }

    Item {
        id: host
        anchors.fill: parent
        anchors.margins: Theme.cardPadding
    }

    // ── CHEVRON: abre o detalhe. Alvo próprio, porque tocar o CORPO
    //  do card é o toggle — os dois gestos não podem se confundir ──
    Hoverable {
        id: chevron

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        width: 22
        height: 22
        visible: card.detail !== ""
        onTapped: card.detailRequested(card.detail)

        Text {
            anchors.centerIn: parent
            text: "󰅂"
            color: chevron.hovered ? Theme.textSecondary : Theme.textMuted
            font { family: Theme.fontIcon; pixelSize: 11 }
            Behavior on color { ColorAnimation { duration: Motion.instant } }
        }
    }
}
