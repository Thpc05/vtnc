pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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
    // App de configuração (janela flutuante, não faz parte da shell)
    readonly property string ipcConfigTarget: "config"

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
            property int maxLauncherResults: 7
            property int batteryWarnLevel: 20
            property bool showTips: true

            // paths / programas externos
            property string wallpaperPath: Paths.home + "/Pictures/Wallpapers"
            property string networkApp: "nm-connection-editor"
            property string bluetoothApp: "blueman-manager"
            property string screenshotPath: Paths.home + "/Pictures/Screenshots"
            property string recordingPath: Paths.home + "/Videos/Recordings"

            // osd / notificações
            property int osdTimeout: 2000
            property bool osdShowPercent: false
            property int notifyTimeout: 4500
            property int maxNotifHistory: 20
            property string backlightFile: "/sys/class/backlight/intel_backlight/brightness"
            property string backlightMaxFile: "/sys/class/backlight/intel_backlight/max_brightness"
            property int backlightPollMs: 300

            // autohide
            property string autoHideAnim: "slide"
            property bool alwaysAutoHide: false
            property real autoHideRevealZone: 4
            property bool autoHideShowOnApp: true
            property bool autoHideShowOnDashboard: true
            property bool autoHideShowOnOsd: true
            property bool autoHideShowOnNotif: true
        }
    }
}
