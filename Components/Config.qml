pragma Singleton
import QtQuick

// ═══════════════════════════════════════════
//  CONFIG — Comportamento da shell (não-estético).
//  Estético é do Theme; o que MUDA em runtime e sobrevive ao boot
//  é do Services/Persist.qml. Aqui é só o que se ajusta na mão.
// ═══════════════════════════════════════════
QtObject {
    // ════════════════════════════════════════
    //  COMPORTAMENTO
    // ════════════════════════════════════════
    readonly property int maxLauncherResults: 7

    // Abaixo deste nível a bateria de emergência aparece ao lado do
    // relógio (100 = sempre visível, útil pra testar)
    readonly property int batteryWarnLevel: 20

    // Tools: true = legenda do selecionado embaixo dos ícones;
    // false = só o destaque de seleção (pill mais baixa)
    readonly property bool showTips: true

    // ════════════════════════════════════════
    //  PATHS
    // ════════════════════════════════════════
    readonly property string wallpaperPath: "/home/thpc/Pictures/Wallpapers"
    // Apps completos, abertos pelos ícones dos widgets
    readonly property string networkApp: "nm-connection-editor"
    readonly property string bluetoothApp: "blueman-manager"
    readonly property string screenshotPath: "/home/thpc/Pictures/Screenshots"
    readonly property string recordingPath: "/home/thpc/Videos/Recordings"

    // ════════════════════════════════════════
    //  IPC TARGETS
    //  Genérico:  qs ipc call island toggle launcher
    //  Por app:   qs ipc -t launcher -c toggle
    // ════════════════════════════════════════
    readonly property string ipcTarget: "island"
    // Modo da ilha: normal ↔ wide
    readonly property string ipcPillTarget: "pill"
    // Barra de topo independente (por baixo da pill)
    readonly property string ipcFramedTarget: "framed"
    readonly property string ipcDashboardTarget: "dashboard"
    readonly property string ipcLauncherTarget: "launcher"
    readonly property string ipcOsdTarget: "osd"
    readonly property string ipcWallpaperTarget: "wallpaper"
    readonly property string ipcToolsTarget: "tools"
    readonly property string ipcSessionTarget: "session"
    readonly property string ipcClipboardTarget: "clipboard"

    // ════════════════════════════════════════
    //  OSD / NOTIFICAÇÕES
    // ════════════════════════════════════════
    readonly property int osdTimeout: 2000
    // Mostrar a porcentagem numérica nos OSDs de volume/brilho
    readonly property bool osdShowPercent: false
    readonly property int notifyTimeout: 4500
    readonly property int maxNotifHistory: 20
    // Backlight (sysfs) — lido por polling pra auto-mostrar o OSD
    readonly property string backlightFile: "/sys/class/backlight/intel_backlight/brightness"
    readonly property string backlightMaxFile: "/sys/class/backlight/intel_backlight/max_brightness"
    readonly property int backlightPollMs: 300

    // ════════════════════════════════════════
    //  AUTOHIDE — a pill (e a framed) se escondem no monitor que
    //  está em fullscreen. Mouse no topo da tela revela de volta.
    // ════════════════════════════════════════
    // Animação: "slide" (sobe pra fora) | "fade" | "retract" (encolhe)
    readonly property string autoHideAnim: "slide"
    // Autohide mesmo SEM fullscreen (a pill vive escondida, revela no topo)
    readonly property bool alwaysAutoHide: false
    // Altura (px) da faixa de hover no topo que revela a pill
    readonly property real autoHideRevealZone: 4
    // O que FORÇA a pill visível apesar do autohide (liga/desliga cada).
    // ATENÇÃO: showOnApp false = abrir o launcher em fullscreen digita
    // numa pill invisível — deixe true a menos que saiba o que quer
    readonly property bool autoHideShowOnApp: true
    readonly property bool autoHideShowOnDashboard: true
    readonly property bool autoHideShowOnOsd: true
    readonly property bool autoHideShowOnNotif: true
}
