import QtQuick

// ═══════════════════════════════════════════
//  PILL FACE — Contrato de um "rosto" da ilha.
//  A Island não conhece nenhuma face concreta: só este contrato.
//
//  Face é o que a ilha VIRA: a barra e os apps. Volume, brilho e
//  notificação NÃO são faces — são conteúdo (Center, NotifReveal),
//  porque o tempo de cada coisa é de quem a mostra, não da ilha.
//
//  Contrato de animação:
//   - a face anima o PRÓPRIO contentWidth/Height quando o conteúdo
//     muda enquanto ela está ativa (a Island segue cru)
//   - transições ENTRE faces são coreografadas pela Island
// ═══════════════════════════════════════════
Item {
    id: face

    // Identidade
    property string name: ""
    // "bar" (face padrão) | "app" (captura teclado/tela)
    property string role: "app"

    // Tamanho que a face quer ter quando está ativa.
    // O RAIO não é da face: é da ilha (IslandTheme.radius, constante).
    // Face nenhuma escolhe o próprio canto — é isso que mantém a borda
    // igual em todos os estados.
    property real contentWidth: 100
    property real contentHeight: 32

    // Apps: capturam teclado e clique-fora-fecha
    property bool grabsKeyboard: false
    // App pede pra SOLTAR o grab (teclado + mask fullscreen) sem
    // fechar — ex: Tools durante o slurp, que precisa da tela livre
    property bool releaseInput: false

    // Setado pela Island: esta face é a atualmente exibida
    property bool active: false

    // Emitido pela face pra pedir pra aparecer
    signal requested()
    // Emitido pela face pra fechar a ilha (Esc no launcher, etc)
    signal closeRequested()

    visible: false // Island controla
}
