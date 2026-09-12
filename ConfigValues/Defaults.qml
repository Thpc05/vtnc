pragma Singleton
import QtQuick
import Quickshell

// ═══════════════════════════════════════════
//  DEFAULTS — O valor de fábrica de cada knob, num lugar só.
//
//  Existe por dois motivos, e o segundo é o que o justifica:
//
//   1. SEMEAR. Os JsonAdapter leem daqui, então uma máquina sem
//      ~/.local/state/vtnc nasce com a shell inteira configurada.
//
//   2. COMPARAR. O app de settings mostra um botão de reverter na
//      linha cujo valor DIFERE do de fábrica. Sem uma fonte separada
//      não haveria com o que comparar: o default vivia dentro do
//      adapter e era destruído no instante em que o arquivo carregava.
//
//  ARMADILHA: os adapters referenciam isto como valor INICIAL. Quando
//  o FileView carrega, ele ATRIBUI por cima e o binding morre — que é
//  o comportamento certo (o arquivo vence o default). Por isso este
//  singleton precisa ser constante: se um valor daqui mudasse em
//  runtime, ele não se propagaria de volta, e as duas fontes
//  divergiriam em silêncio.
//
//  Adicionar um knob = 1 entrada aqui + 1 property no adapter que a
//  referencia + 1 readonly no singleton + 1 linha no app de settings.
// ═══════════════════════════════════════════
QtObject {
    // ════════════════════════════════════════
    //  TEMA (cores, fontes, raio, espaçamento)
    // ════════════════════════════════════════
    readonly property var theme: ({
        accent: "#3dd1b0",
        surface: "#1f1f23",
        textPrimary: "#ffffff",
        textSecondary: "#a0a0a0",
        textMuted: "#555a64",
        danger: "#ff5555",
        separator: "#16ffffff",
        shadow: "#cc000000",
        card: "#141416",
        border: "#14ffffff",
        hoverLayer: "#2effffff",
        fontDisplay: "SF Pro Display",
        fontMono: "SF Mono",
        fontIcon: "JetBrainsMono Nerd Font Propo",
        contentPadding: 14,
        cardPadding: 12,
        controlWidth: 600,
        launcherWidth: 520,
        radiusIsland: 24,
        radiusCard: 18,
        radiusScreen: 24,
        controlCardHeight: 64,
        controlGap: 16,
        widgetMediaBlur: 0.6,
        osdPxPerPct: 2,
        notifHistoryMaxHeight: 180
    })

    // ════════════════════════════════════════
    //  MOVIMENTO (durações, assentamento, hover)
    // ════════════════════════════════════════
    readonly property var motion: ({
        instant: 120,
        quick: 150,
        standard: 320,
        track: 140,
        overshoot: 1.0,
        hoverDelay: 350,
        hoverGrace: 450
    })

    // ════════════════════════════════════════
    //  ILHA (coreografia do morph, geometria)
    // ════════════════════════════════════════
    readonly property var island: ({
        faceFadeOut: 90,
        morphDuration: 340,
        faceFadeInDelay: 200,
        faceFadeIn: 160,
        faceScaleOut: 0.94,
        faceScaleIn: 0.92,
        marginTop: 6,
        width: 100,
        height: 32,
        wideWidth: 150,
        wideHeight: 32
    })

    // ════════════════════════════════════════
    //  COMPORTAMENTO (autohide, osd, paths, wallpaper)
    // ════════════════════════════════════════
    readonly property var config: ({
        maxLauncherResults: 7,
        batteryWarnLevel: 20,
        showTips: true,
        wallpaperPath: Paths.home + "/Pictures/Wallpapers",
        networkApp: "nm-connection-editor",
        bluetoothApp: "blueman-manager",
        screenshotPath: Paths.home + "/Pictures/Screenshots",
        recordingPath: Paths.home + "/Videos/Recordings",
        wallpaperTransition: "wipe",
        wallpaperTransitionMs: 900,
        wallpaperTintsShell: true,
        matugenScheme: "scheme-tonal-spot",
        matugenPrefer: "saturation",
        osdTimeout: 2000,
        osdShowPercent: false,
        notifyTimeout: 4500,
        maxNotifHistory: 20,
        backlightFile: "/sys/class/backlight/intel_backlight/brightness",
        backlightMaxFile: "/sys/class/backlight/intel_backlight/max_brightness",
        backlightPollMs: 300,
        autoHideAnim: "slide",
        alwaysAutoHide: false,
        autoHideRevealZone: 4,
        autoHideShowOnApp: true,
        autoHideShowOnControlCenter: true,
        autoHideShowOnOsd: true,
        autoHideShowOnNotif: true
    })
}
