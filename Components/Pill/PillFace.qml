import ".."
import QtQuick

// ═══════════════════════════════════════════
//  PILL FACE — Contrato de um "rosto" da ilha.
//  A Pill não conhece nenhuma face concreta: só este contrato.
//
//  Face é o que a ilha VIRA: a barra e os apps. Volume, brilho e
//  notificação NÃO são faces — são conteúdo (Center, NotifReveal),
//  porque o tempo de cada coisa é de quem a mostra, não da ilha.
//
//  Contrato de animação:
//   - a face anima o PRÓPRIO contentWidth/Height quando o conteúdo
//     muda enquanto ela está ativa (a Pill segue cru)
//   - transições ENTRE faces são coreografadas pela Pill
// ═══════════════════════════════════════════
Item {
    id: face

    // Identidade
    property string name: ""
    // "bar" (face padrão) | "app" (captura teclado/tela)
    property string role: "app"

    // Tamanho que a face quer ter quando está ativa
    property real contentWidth: 100
    property real contentHeight: 32
    // -1 = radius padrão (metade da altura, limitado por Pill_Theme.radius)
    property real contentRadius: 32

    // Apps: capturam teclado e clique-fora-fecha
    property bool grabsKeyboard: false
    // App pede pra SOLTAR o grab (teclado + mask fullscreen) sem
    // fechar — ex: Tools durante o slurp, que precisa da tela livre
    property bool releaseInput: false

    // Setado pela Pill: esta face é a atualmente exibida
    property bool active: false

    // Emitido pela face pra pedir pra aparecer
    signal requested()
    // Emitido pela face pra fechar a ilha (Esc no launcher, etc)
    signal closeRequested()

    visible: false // Pill controla
}
