pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

// ═══════════════════════════════════════════
//  CONFIG — Comportamento da shell (não-estético).
//  Estético é do Theme (cores, raio, espaço) e do Motion (tempos).
//  Aqui mora o que a shell FAZ: quanto tempo, quantos itens, quais
//  programas externos, onde ficam os arquivos.
//
//  PERSISTÊNCIA: mesmo padrão do Config/Motion.qml (armadilhas do
//  FileView documentadas lá).
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var data: d
    property bool loaded: false

    // ════════════════════════════════════════
    //  COMPORTAMENTO
    // ════════════════════════════════════════
    readonly property int maxLauncherResults: d.maxLauncherResults
    // Abaixo deste nível a bateria de emergência aparece ao lado do
    // relógio (100 = sempre visível, útil pra testar)
    readonly property int batteryWarnLevel: d.batteryWarnLevel
    // Tools: true = legenda do selecionado embaixo dos ícones;
    // false = só o destaque de seleção (ilha mais baixa)
    readonly property bool showTips: d.showTips

    // ════════════════════════════════════════
    //  PATHS / PROGRAMAS EXTERNOS
    // ════════════════════════════════════════
    readonly property string wallpaperPath: d.wallpaperPath
    // Apps completos, abertos pelos ícones dos widgets
    readonly property string networkApp: d.networkApp
    readonly property string bluetoothApp: d.bluetoothApp
    readonly property string screenshotPath: d.screenshotPath
    readonly property string recordingPath: d.recordingPath

    // ════════════════════════════════════════
    //  PAPEL DE PAREDE (awww) E CORES (matugen)
    // ════════════════════════════════════════
    // none · simple · fade · left · right · top · bottom · wipe ·
    // wave · grow · center · any · outer · random
    readonly property string wallpaperTransition: d.wallpaperTransition
    readonly property int wallpaperTransitionMs: d.wallpaperTransitionMs
    // Trocar o papel de parede re-tinge a shell pela paleta dele.
    // O FUNDO não entra nisso: Theme.bg é fixo #000000
    readonly property bool wallpaperTintsShell: d.wallpaperTintsShell
    // scheme-tonal-spot · scheme-vibrant · scheme-content ·
    // scheme-expressive · scheme-fidelity · scheme-neutral ·
    // scheme-monochrome · scheme-fruit-salad · scheme-rainbow
    readonly property string matugenScheme: d.matugenScheme
    // Qual cor candidata vence quando a imagem tem várias:
    // darkness · lightness · saturation · less-saturation · value
    readonly property string matugenPrefer: d.matugenPrefer

    // ════════════════════════════════════════
    //  IPC TARGETS — NÃO são configuráveis, e de propósito.
    //  Estes nomes são CONTRATO EXTERNO: os binds do Hyprland chamam
    //  `qs ipc -t launcher -c toggle`. Um slider no config app que
    //  mudasse isto quebraria o teclado sem dar nenhum sinal.
    //  Mudar aqui = mudar junto no hyprland.conf.
    //
    //  Genérico:  qs ipc call island toggle launcher
    //  Por app:   qs ipc -t launcher -c toggle
    // ════════════════════════════════════════
    readonly property string ipcTarget: "island"
    // Modo da ilha: normal ↔ wide
    readonly property string ipcPillTarget: "pill"
    readonly property string ipcDashboardTarget: "dashboard"
    readonly property string ipcLauncherTarget: "launcher"
    readonly property string ipcOsdTarget: "osd"
    readonly property string ipcWallpaperTarget: "wallpaper"
    readonly property string ipcToolsTarget: "tools"
    readonly property string ipcSessionTarget: "session"
    readonly property string ipcClipboardTarget: "clipboard"
    // App de settings (janela flutuante, não faz parte da shell)
    readonly property string ipcSettingsTarget: "settings"

    // ════════════════════════════════════════
    //  OSD / NOTIFICAÇÕES
    // ════════════════════════════════════════
    readonly property int osdTimeout: d.osdTimeout
    // Mostrar a porcentagem numérica nos OSDs de volume/brilho
    readonly property bool osdShowPercent: d.osdShowPercent
    readonly property int notifyTimeout: d.notifyTimeout
    readonly property int maxNotifHistory: d.maxNotifHistory
    // Backlight (sysfs) — lido por polling pra auto-mostrar o OSD
    readonly property string backlightFile: d.backlightFile
    readonly property string backlightMaxFile: d.backlightMaxFile
    readonly property int backlightPollMs: d.backlightPollMs

    // ════════════════════════════════════════
    //  AUTOHIDE — a ilha se esconde no monitor que está em
    //  fullscreen. Mouse no topo da tela revela de volta.
    // ════════════════════════════════════════
    // Animação: "slide" (sobe pra fora) | "fade" | "retract" (encolhe)
    readonly property string autoHideAnim: d.autoHideAnim
    // Autohide mesmo SEM fullscreen (a ilha vive escondida)
    readonly property bool alwaysAutoHide: d.alwaysAutoHide
    // Altura (px) da faixa de hover no topo que revela a ilha
    readonly property real autoHideRevealZone: d.autoHideRevealZone
    // O que FORÇA a ilha visível apesar do autohide (liga/desliga cada).
    // ATENÇÃO: showOnApp false = abrir o launcher em fullscreen digita
    // numa ilha invisível — deixe true a menos que saiba o que quer
    readonly property bool autoHideShowOnApp: d.autoHideShowOnApp
    readonly property bool autoHideShowOnDashboard: d.autoHideShowOnDashboard
    readonly property bool autoHideShowOnOsd: d.autoHideShowOnOsd
    readonly property bool autoHideShowOnNotif: d.autoHideShowOnNotif

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

        path: Paths.config
        blockLoading: true

        onLoaded: root.loaded = true
        onLoadFailed: {
            root.loaded = true
            writeAdapter()
        }
        onAdapterUpdated: root.saveSoon()

        adapter: JsonAdapter {
            id: d

            // comportamento
            property int maxLauncherResults: Defaults.config.maxLauncherResults
            property int batteryWarnLevel: Defaults.config.batteryWarnLevel
            property bool showTips: Defaults.config.showTips

            // paths / programas externos
            property string wallpaperPath: Defaults.config.wallpaperPath
            property string networkApp: Defaults.config.networkApp
            property string bluetoothApp: Defaults.config.bluetoothApp
            property string screenshotPath: Defaults.config.screenshotPath
            property string recordingPath: Defaults.config.recordingPath

            // wallpaper / matugen
            property string wallpaperTransition: Defaults.config.wallpaperTransition
            property int wallpaperTransitionMs: Defaults.config.wallpaperTransitionMs
            property bool wallpaperTintsShell: Defaults.config.wallpaperTintsShell
            property string matugenScheme: Defaults.config.matugenScheme
            property string matugenPrefer: Defaults.config.matugenPrefer

            // osd / notificações
            property int osdTimeout: Defaults.config.osdTimeout
            property bool osdShowPercent: Defaults.config.osdShowPercent
            property int notifyTimeout: Defaults.config.notifyTimeout
            property int maxNotifHistory: Defaults.config.maxNotifHistory
            property string backlightFile: Defaults.config.backlightFile
            property string backlightMaxFile: Defaults.config.backlightMaxFile
            property int backlightPollMs: Defaults.config.backlightPollMs

            // autohide
            property string autoHideAnim: Defaults.config.autoHideAnim
            property bool alwaysAutoHide: Defaults.config.alwaysAutoHide
            property real autoHideRevealZone: Defaults.config.autoHideRevealZone
            property bool autoHideShowOnApp: Defaults.config.autoHideShowOnApp
            property bool autoHideShowOnDashboard: Defaults.config.autoHideShowOnDashboard
            property bool autoHideShowOnOsd: Defaults.config.autoHideShowOnOsd
            property bool autoHideShowOnNotif: Defaults.config.autoHideShowOnNotif
        }
    }
}
