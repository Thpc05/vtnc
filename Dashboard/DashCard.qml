import QtQuick
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  DASH CARD — A casca de um card do Control Center.
//
//  Substituiu o DashWidget, e o que ele perdeu é o ponto: não existe
//  mais `expanded`, `sizeIdle/sizeExpand`, `expandDir`, `gridCol/Row`,
//  drag nem pin. Card tem TAMANHO FIXO e posição declarada no
//  Dashboard.qml — quem quer ver mais abre o detalhe.
//
//  Isso apagou o solver de colisão, o empurrão-em-sombra e a
//  persistência de layout. Aquilo resolvia um problema que a própria
//  dashboard criava: peças que mudavam de tamanho sozinhas e
//  precisavam se desviar. Sem tamanho variável, não há o que desviar.
//
//  `lit` é o estado LIGADO (Wi-Fi ligado, BT ligado): o card inteiro
//  vira accent, como no Control Center. É diferente do hover, que só
//  clareia a mira.
// ═══════════════════════════════════════════
Rectangle {
    id: card

    // Ligado = card em accent. Desligado = card escuro
    property bool lit: false
    // Abre o detalhe (lista de redes, dispositivos, saídas de áudio).
    // Vazio = o card não tem detalhe e nem mostra o chevron
    property string detail: ""

    signal tapped()
    signal detailRequested(string nome)

    default property alias content: host.data

    readonly property bool hovered: mira.hovered

    // Cor do conteúdo — todo card lê isto em vez de escolher sozinho,
    // senão o texto some quando o fundo vira accent
    readonly property color ink: lit ? Theme.bg : Theme.textPrimary
    readonly property color inkSoft: lit ? Qt.rgba(0, 0, 0, 0.55)
                                         : Theme.textSecondary

    radius: Theme.radiusCard
    color: lit ? Theme.accent : Theme.hoverLayer
    Behavior on color { ColorAnimation { duration: Motion.instant } }
    clip: true

    HoverHandler { id: mira }

    // Clarear no hover SEM brigar com o accent: uma camada por cima,
    // não uma segunda cor de fundo. Assim vale nos dois estados
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: card.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
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
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        width: 24
        height: 24
        visible: card.detail !== ""
        onTapped: card.detailRequested(card.detail)

        Text {
            anchors.centerIn: parent
            text: "󰅂"
            color: card.inkSoft
            font { family: Theme.fontIcon; pixelSize: 12 }
        }
    }
}
