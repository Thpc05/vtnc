pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════
//  THEME — Estética geral da shell.
//
//  A DIVISÃO: aqui moram cores, fontes e a aparência do CONTEÚDO
//  (apps, OSDs, dashboard, reveals). A casca da ilha — raio, margem,
//  tempos do morph — mora em Island/IslandTheme.qml. A escala de
//  movimento é do Config/Motion.qml.
//
//  Na dúvida: se dois conteúdos diferentes usariam o token, é daqui.
//  Se só a ilha usa, é de lá.
//
//  PERSISTÊNCIA: mesmo padrão do Config/Motion.qml — os valores e
//  seus defaults moram no JsonAdapter no fim do arquivo, a shell lê
//  pelas readonly properties, o config app escreve em Theme.data.*.
//  As armadilhas do FileView estão documentadas lá.
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var data: d
    property bool loaded: false

    // ════════════════════════════════════════
    //  CORES
    // ════════════════════════════════════════
    readonly property color accent: d.accent
    readonly property color surface: d.surface
    readonly property color textPrimary: d.textPrimary
    readonly property color textSecondary: d.textSecondary
    readonly property color textMuted: d.textMuted
    readonly property color danger: d.danger
    readonly property color separator: d.separator
    readonly property color shadow: d.shadow
    // "Mira": fundo de TODO efeito hover/selected da shell.
    // É uma CAMADA (branco com alfa), feita pra somar sobre o que
    // estiver embaixo — não serve de cor de superfície
    readonly property color hoverLayer: d.hoverLayer

    // Superfície de card: o degrau acima do preto. Usar a hoverLayer
    // aqui era o erro que deixava os cards cinza-claro demais — ela é
    // camada de mira, não superfície. No escuro do iOS o card fica em
    // ~#1C1C1E sobre fundo quase preto; este é o mesmo degrau
    readonly property color card: d.card

    // O FUNDO PRINCIPAL É FIXO e fica FORA do que se pode configurar.
    // É uma decisão de projeto, não um esquecimento: a ilha é preta,
    // ponto. Pills DENTRO dela podem ter cor; o fundo, não. Isso
    // também é o que mantém a shell coerente quando as cores
    // passarem a vir do wallpaper (matugen) — o preto não negocia.
    readonly property color bg: "#000000"
    // O canto da tela é uma máscara do mesmo preto: se divergisse do
    // bg apareceria uma casquinha de cor na quina
    readonly property color screenCornerColor: bg

    // ════════════════════════════════════════
    //  FONTES
    // ════════════════════════════════════════
    readonly property string fontDisplay: d.fontDisplay
    readonly property string fontMono: d.fontMono
    readonly property string fontIcon: d.fontIcon

    // (o FADE TARDIO saiu com a dashboard: era ela que precisava de um
    //  ponto de entrada próprio pro conteúdo não "pipocar" ao crescer
    //  dentro da barra. Como face de app, ela usa a coreografia de
    //  morph da ilha, que já cuida disso)

    // ════════════════════════════════════════
    //  CONTEÚDO — o que a ilha hospeda
    // ════════════════════════════════════════
    // Respiro interno de apps/OSDs: é o padding do CONTEÚDO, não da
    // ilha — por isso é geral
    readonly property real contentPadding: d.contentPadding
    // Respiro dentro de um card (widget da dashboard)
    readonly property real cardPadding: d.cardPadding
    // Tamanho que os apps pedem quando abrem
    readonly property real dashWidth: d.dashWidth
    readonly property real launcherWidth: d.launcherWidth

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
    //  canto dela é constante em qualquer altura. Derivar o raio da
    //  altura — stadium quando baixa, squircle quando alta — foi
    //  testado, e o que incomodava era o canto MUDAR na abertura.
    //
    //  Consequência: a cadeia concêntrica tem raiz no CARD, não na
    //  ilha. Herdar de uma ilha de canto baixo achataria os widgets.
    //  O que sobra de concêntrico é card → chip, e é o par que importa
    //  de verdade: o chip mora NO canto do card, encostado nele; o
    //  card flutua no meio da ilha, longe do canto dela.
    //
    //  FORA da cadeia (e de propósito): indicadores que são FORMA, não
    //  moldura — o dot do workspace, a barra de progresso, o ponto de
    //  notificação não lida. Esses têm o raio que a forma pede.
    //  Os fundos de linha de lista (Launcher, Clipboard, Wallpaper)
    //  ainda estão soltos em 10/12/14 — viram um rung próprio quando
    //  esses apps forem retrabalhados.
    // ════════════════════════════════════════
    readonly property real radiusIsland: d.radiusIsland
    readonly property real radiusCard: d.radiusCard
    // DERIVADO: não vai pro adapter. Salvar o chip separado deixaria
    // guardar um estado que contradiz a regra concêntrica
    readonly property real radiusChip: Math.max(0, radiusCard - cardPadding)
    // Fora da cadeia: a tela não mora dentro de nada
    readonly property real radiusScreen: d.radiusScreen

    // ════════════════════════════════════════
    //  DASHBOARD
    //  A altura total deriva do layout — não existe dashHeight fixo
    // ════════════════════════════════════════
    // Altura de um card de toggle. O card de mídia vale dois deles;
    // os sliders, 0.72 — ver Dashboard/Dashboard.qml
    readonly property real dashCell: d.dashCell
    readonly property real dashGap: d.dashGap
    // Blur da capa no fundo do MediaWidget (0 → 1)
    readonly property real widgetMediaBlur: d.widgetMediaBlur

    // ════════════════════════════════════════
    //  OSD / NOTIFICAÇÕES
    // ════════════════════════════════════════
    // Largura da barra: pixels por 1% (volume/brilho)
    readonly property real osdPxPerPct: d.osdPxPerPct
    readonly property real notifHistoryMaxHeight: d.notifHistoryMaxHeight

    // ── persistência (ver Config/Motion.qml para as armadilhas) ──
    function saveSoon() {
        if (loaded)
            saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: 100
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file

        path: Paths.theme
        blockLoading: true

        onLoaded: root.loaded = true
        onLoadFailed: {
            root.loaded = true
            writeAdapter()
        }
        onAdapterUpdated: root.saveSoon()

        adapter: JsonAdapter {
            id: d

            // Cores como STRING, não `property color`: JSON não tem
            // tipo cor, e guardar o tipo nativo dependeria de uma
            // serialização que não dá pra verificar aqui. O hex é o
            // que o config app edita de qualquer jeito, e o QML
            // converte string→color sozinho nos bindings acima.
            // (bg fica de fora: é fixo)
            property string accent: "#3dd1b0"
            property string surface: "#1f2735"
            property string textPrimary: "#ffffff"
            property string textSecondary: "#a0a0a0"
            property string textMuted: "#555a64"
            property string danger: "#ff5555"
            property string separator: "#16ffffff"
            property string shadow: "#cc000000"
            property string card: "#141416"
            property string hoverLayer: "#2effffff"

            // fontes
            property string fontDisplay: "SF Pro Display"
            property string fontMono: "SF Mono"
            property string fontIcon: "JetBrainsMono Nerd Font Propo"

            // conteúdo
            property real contentPadding: 14
            property real cardPadding: 12
            property real dashWidth: 600
            property real launcherWidth: 520

            // raio (radiusChip é derivado — não entra aqui)
            property real radiusIsland: 24
            property real radiusCard: 18
            property real radiusScreen: 22

            // dashboard
            property real dashCell: 64
            property real dashGap: 8
            property real widgetMediaBlur: 0.6

            // osd / notificações
            property real osdPxPerPct: 2
            property real notifHistoryMaxHeight: 180
        }
    }
}
