pragma Singleton
import QtQuick

// ═══════════════════════════════════════════
//  THEME — Estética geral da shell.
//  Cores fixas por enquanto (futuro: adaptar ao wallpaper).
//
//  A DIVISÃO: aqui moram cores, fontes e a aparência do CONTEÚDO
//  (apps, OSDs, dashboard, reveals). A casca da ilha — raio, margem,
//  tempos do morph — mora em Components/Pill/Pill_Theme.qml.
//
//  Na dúvida: se dois conteúdos diferentes usariam o token, é daqui.
//  Se só a ilha usa, é de lá.
// ═══════════════════════════════════════════
QtObject {
    // ════════════════════════════════════════
    //  CORES
    // ════════════════════════════════════════
    readonly property color accent: "#3dd1b0"
    readonly property color bg: "#000000"
    readonly property color surface: "#1f2735"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#a0a0a0"
    readonly property color textMuted: "#555a64"
    readonly property color danger: "#ff5555"
    readonly property color separator: "#16ffffff"
    readonly property color shadow: "#cc000000"
    // "Mira": fundo de TODO efeito hover/selected da shell
    readonly property color hoverLayer: "#2effffff"

    // ════════════════════════════════════════
    //  FONTES
    // ════════════════════════════════════════
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontMono: "SF Mono"
    readonly property string fontIcon: "JetBrainsMono Nerd Font Propo"

    // ════════════════════════════════════════
    //  TEMPOS E CURVAS — não moram mais aqui.
    //  A escala de movimento é do Components/Motion.qml (durações +
    //  assentamento) e os dois componentes de animação são o Settle
    //  (forma) e o Smooth (posição/opacidade).
    //  A coreografia do morph, essa é da ilha: Pill/Pill_Theme.qml.
    // ════════════════════════════════════════

    // ════════════════════════════════════════
    //  FADE TARDIO — conteúdo que entra na parte final de um morph.
    //  Não é animação própria: deriva do driver (o morph já anima).
    //  `start` (fração 0-1) = onde o conteúdo começa a aparecer.
    //   0.5 = só na segunda metade (seco); menor = entra antes e sobe
    //   mais gradual (fade mais suave/lento na percepção).
    // ════════════════════════════════════════
    function lateReveal(x, start) {
        return Math.max(0, Math.min(1, (x - start) / (1 - start)))
    }
    // Padrão (equivale ao antigo `x*2-1`)
    readonly property real lateStart: 0.3
    // Dashboard: mais suave que o padrão (o conteúdo "pipocava")
    readonly property real dashContentStart: 0.9

    // ════════════════════════════════════════
    //  CONTEÚDO — o que a ilha hospeda
    // ════════════════════════════════════════
    // Respiro interno de apps/OSDs: é o padding do CONTEÚDO, não da
    // pill — por isso é geral
    readonly property real contentPadding: 14
    // Respiro dentro de um card (widget da dashboard)
    readonly property real cardPadding: 12
    // Tamanho que os apps pedem quando abrem
    readonly property real dashWidth: 600
    readonly property real launcherWidth: 520

    // ════════════════════════════════════════
    //  RAIO — a borda da shell, uma regra só.
    //
    //  Filosofia Apple: cantos CONCÊNTRICOS. Quando B mora dentro de A
    //  com um respiro p, o raio de B é o de A MENOS p. Só assim as
    //  duas curvas correm paralelas; raios escolhidos a olho fazem a
    //  curva de dentro brigar com a de fora, e é isso que faz uma
    //  interface parecer montada em vez de desenhada.
    //
    //  A ILHA fica FORA da cadeia, e isso é decisão, não descuido: o
    //  canto dela é CONSTANTE em qualquer altura (barra, reveal
    //  aberto, dashboard). Derivar o raio da altura — stadium quando
    //  baixa, squircle quando alta — foi testado, e o que incomodava
    //  era justamente o canto MUDAR durante a abertura.
    //
    //  Consequência: a cadeia concêntrica tem raiz no CARD, não na
    //  ilha. Herdar de uma ilha de canto 16 daria card = 16 − 14 = 2 e
    //  achataria os widgets. E, já que a ilha não muda mais de canto,
    //  ela deixou de ser uma referência útil pro que mora dentro.
    //
    //  O que sobra de concêntrico é card → chip — e é o par que
    //  importa de verdade: o chip mora NO canto do card, encostado
    //  nele. O card flutua no meio da ilha, longe do canto dela.
    //
    //  FORA da cadeia (e de propósito): indicadores que são FORMA, não
    //  moldura — o dot do workspace, a barra de progresso, o ponto de
    //  notificação não lida. Esses têm o raio que a forma pede.
    //  Os fundos de linha de lista (Launcher, Clipboard, Wallpaper)
    //  ainda estão soltos em 10/12/14 — viram um rung próprio quando
    //  esses apps forem retrabalhados.
    // ════════════════════════════════════════
    //  Canto da ilha, igual em TODOS os estados. TETO PRÁTICO: metade
    //  da altura da barra (Pill_Theme.height / 2 = 16). Acima disso a
    //  barra baixa clampa sozinha e o canto volta a variar com a
    //  altura — que é exatamente o que não queremos aqui.
    readonly property real radiusIsland: 16

    //  Raiz da cadeia do conteúdo. O clamp não é decoração: a cadeia
    //  subtrai, então baixar o card abaixo do cardPadding levaria o
    //  chip a um raio NEGATIVO. Com o config app isso vira um slider —
    //  e um slider tem que poder ir até o fim sem quebrar nada.
    readonly property real radiusCard: 18
    readonly property real radiusChip: Math.max(0, radiusCard - cardPadding)
    // Fora da cadeia: a tela não mora dentro de nada
    readonly property real radiusScreen: 22

    // ════════════════════════════════════════
    //  DASHBOARD (quebra-cabeça de widgets)
    //  A altura total deriva do layout — não existe dashHeight fixo
    // ════════════════════════════════════════
    readonly property real dashTopHeight: 44
    readonly property int dashColumns: 4
    readonly property real dashCell: 64
    readonly property real dashGap: 8
    readonly property color widgetBgColor: bg
    readonly property color widgetBorderColor: bg
    readonly property color widgetBorderHoverColor: accent
    // Blur da capa no fundo do MediaWidget (0 → 1)
    readonly property real widgetMediaBlur: 0.6

    // ════════════════════════════════════════
    //  OSD
    // ════════════════════════════════════════
    // Largura da barra: pixels por 1% (volume/brilho)
    readonly property real osdPxPerPct: 2

    // ════════════════════════════════════════
    //  NOTIFICAÇÕES (histórico no hover)
    // ════════════════════════════════════════
    readonly property real notifHistoryMaxHeight: 180

    // ════════════════════════════════════════
    //  SCREEN CORNERS — decoração da tela.
    //  O canto é recortado: a curva "fecha" o canto. 0 desliga.
    // ════════════════════════════════════════
    readonly property color screenCornerColor: "#000000"
}
