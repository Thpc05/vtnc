import QtQuick

// ═══════════════════════════════════════════
//  HOVERABLE — A "mira" da shell: o alvo que acende sob o mouse.
//
//  Este padrão estava copiado ~29 vezes à mão (um Rectangle de fundo,
//  um HoverHandler, um TapHandler e o Behavior da cor), e cada cópia
//  tinha escolhido o próprio raio — havia CINCO valores diferentes
//  pra mesma coisa. Aqui é um só.
//
//  Uso: dê um id, o tamanho, e ponha o conteúdo dentro.
//
//      Hoverable {
//          id: btIcon
//          width: 24; height: 22
//          onTapped: Service.fazAlgo()
//          Text {
//              anchors.centerIn: parent
//              text: "󰂯"
//              color: btIcon.hovered ? Theme.textPrimary : Theme.textMuted
//              Behavior on color { ColorAnimation { duration: Motion.instant } }
//          }
//      }
//
//  O `id:` NÃO é opcional se o conteúdo precisa reagir ao hover.
//  Escrever só `hovered` dentro do filho NÃO funciona — e falha em
//  silêncio, o que é pior: o fundo acende normalmente e só a cor do
//  conteúdo fica presa. Em QML uma expressão resolve contra o próprio
//  objeto, contra os ids, e contra a RAIZ DO ARQUIVO onde foi
//  escrita — nunca contra o objeto que a envolve lexicalmente.
//  (`parent.hovered` também funciona, já que o conteúdo é filho
//  direto; o id é mais claro e sobrevive a aninhamento.)
//
//  Sem `onTapped` ele é só feedback visual — o TapHandler continua
//  montado (custa nada) e o sinal fica sem ouvinte.
//
//  NÃO é o lugar da espera do hover: isto acende na hora, de
//  propósito. Atrasar um realce faria a shell parecer travada. Quem
//  ABRE alguma coisa ao ser mirado usa o HoverGroup, que é onde o
//  openDelay mora.
// ═══════════════════════════════════════════
Item {
    id: root

    // Raio da mira. Default = o rung de chip da cadeia concêntrica;
    // sobrescreva só quando o alvo não for um chip
    property real radius: Theme.radiusChip

    // Mirado agora. O conteúdo lê isto por escopo, sem precisar de id
    readonly property bool hovered: hoverH.hovered

    // Botões que contam como toque (default: só o esquerdo)
    property alias acceptedButtons: tapH.acceptedButtons

    signal tapped()

    // O fundo que acende
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.hovered ? Theme.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    // Conteúdo declarado no uso entra como filho DIRETO — não num
    // host intermediário. Assim `parent` lá dentro é o Hoverable, e
    // não um Item anônimo sem `hovered`. Como o fundo é declarado
    // acima, o conteúdo é anexado depois e desenha por cima
    default property alias content: root.data

    HoverHandler { id: hoverH }

    TapHandler {
        id: tapH
        // ReleaseWithinBounds: arrastar pra fora e soltar não conta
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.tapped()
    }
}
