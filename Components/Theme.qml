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
    //  BOUNCE — personalidade das animações
    //  Aplicado a TODA animação de tamanho/expansão (via Anim.qml):
    //  0 = assenta seco · 1 ≈ sutil · 1.70158 = padrão Qt · 3 = exagerado
    // ════════════════════════════════════════
    readonly property real bounce: 0
    // Duração padrão de um Anim (sobrescrevível no uso)
    readonly property int animDuration: 300

    // ════════════════════════════════════════
    //  TEMPOS GERAIS (ms)
    //  (a coreografia do morph é da ilha — vive no Pill_Theme)
    // ════════════════════════════════════════
    // Expansões de conteúdo (hover, notificação mirada, reveal)
    readonly property int expandDuration: 320
    // Dashboard: pesa como uma troca de face, mas não passa pela
    // coreografia do morph — cresce direto. Sem tempo próprio ela
    // assenta antes dos apps e parece disparada do lado deles
    readonly property int dashDuration: 430
    // Tracking dos sliders OSD (volume/brilho com botão segurado)
    readonly property int osdTrackDuration: 140
    // Fades genéricos de conteúdo
    readonly property int fadeDuration: 150
    // Feedback de hover (cor/mira/escala de botões)
    readonly property int hoverFade: 120

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
    // Tamanho que os apps pedem quando abrem
    readonly property real dashWidth: 600
    readonly property real launcherWidth: 520

    // ════════════════════════════════════════
    //  DASHBOARD (quebra-cabeça de widgets)
    //  A altura total deriva do layout — não existe dashHeight fixo
    // ════════════════════════════════════════
    readonly property real dashTopHeight: 44
    readonly property int dashColumns: 4
    readonly property real dashCell: 64
    readonly property real dashGap: 8
    readonly property real widgetRadius: 20
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
    //  SCREEN CORNERS — decoração da tela
    //  Positivo = canto recortado (a curva "fecha" o canto).
    //  NEGATIVO = curva invertida: o preto avança pra dentro e a
    //  curva sai pra fora — o visual "framed".
    // ════════════════════════════════════════
    readonly property real screenCornerRadius: 22
    readonly property color screenCornerColor: "#000000"
}
