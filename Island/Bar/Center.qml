import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../ConfigValues"
import "../../Services"
import "../../Ui"

// ═══════════════════════════════════════════
//  CENTER — O miolo da ilha: um slot só, uma coisa por vez.
//
//  Prioridade: OSD (volume/brilho) > mídia (título) > relógio.
//  Quem toma o centro empresta a mesma mecânica: um driver `mode`
//  (0→1), crossfade, e `extraWidth` — o quanto quem hospeda deve
//  crescer pra caber o tomador, voltando ao normal quando o tempo
//  passa.
//
//  Não desenha borda nem fundo: quem hospeda monta e soma o
//  extraWidth na própria largura.
//
//  ARMADILHA: largura SEMPRE de implicitWidth, nunca de width —
//  medir o próprio width aqui realimenta o layout e trava a shell
//  inteira num polish loop.
// ═══════════════════════════════════════════
Item {
    id: root

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    // ═══════════════════════════════════════
    //  QUEM ESTÁ NO CENTRO
    // ═══════════════════════════════════════
    // Mídia: some sozinha depois de uns segundos (o OSD atropela)
    property bool showMedia: false
    property string shownTitle: ""

    readonly property string shown:
          OsdService.showing ? OsdService.active
        : showMedia ? "media"
        : "clock"
    readonly property bool taken: shown !== "clock"

    // DRIVER único: fades e largura derivam dele
    property real mode: taken ? 1 : 0
    Behavior on mode {
        // `mode` vira LARGURA (extraWidth) — por isso assenta
        Settle {}
    }

    // Quem tomou por ÚLTIMO — e segue dono da largura enquanto a
    // saída anima.
    // ARMADILHA: na saída, `shown` volta pro relógio no mesmo frame
    // em que o tempo acaba, mas a animação só começou. Lendo `shown`
    // direto, a largura vira 0 na hora e o extra (largura × mode)
    // SALTA em vez de encolher — o mode animava sozinho, multiplicando
    // um valor que já tinha morrido.
    property string lastTake: "clock"
    onShownChanged: if (shown !== "clock") lastTake = shown

    // Largura de quem tomou (mantida durante a volta)
    readonly property real takeWidth:
          lastTake === "volume" ? volumeTake.implicitWidth
        : lastTake === "brightness" ? brightTake.implicitWidth
        : lastTake === "media" ? mediaTake.implicitWidth
        : 0

    // Quanto quem hospeda deve crescer pro tomador caber
    readonly property real extraWidth:
        Math.max(0, takeWidth - timeText.implicitWidth) * mode

    implicitWidth: timeText.implicitWidth + extraWidth
    implicitHeight: timeText.implicitHeight
    // Explícito: num Row/Column o pai não dimensiona o filho, e um
    // Item sem width some sem avisar
    width: implicitWidth
    height: implicitHeight

    // Ignora o estado inicial no startup
    property bool ready: false
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }

    Timer {
        id: mediaTimer
        interval: 3000
        onTriggered: root.showMedia = false
    }

    // Escuta a troca de faixa de TODOS os players: o ativo pode não
    // ser o que mudou de música agora
    Instantiator {
        model: Mpris.players

        Connections {
            required property var modelData
            target: modelData
            function onTrackTitleChanged() {
                if (root.ready && modelData.trackTitle !== "") {
                    root.shownTitle = modelData.trackTitle
                    root.showMedia = true
                    mediaTimer.restart()
                }
            }
        }
    }

    // ═══════════════════════════════════════
    //  O SLOT — crossfade entre o relógio e quem toma.
    //  Todos ancorados direto no root: um wrapper aqui teria que ler
    //  root.implicitWidth, que sai daqui de dentro — e a largura
    //  resolvia pra zero (o centro sumia da barra sem erro nenhum).
    // ═══════════════════════════════════════

    // ── RELÓGIO (o padrão) ──
    Text {
        id: timeText

        anchors.centerIn: parent
        text: Qt.formatDateTime(sysClock.date, "HH:mm")
        opacity: 1 - root.mode
        visible: opacity > 0
        color: Theme.textPrimary
        font {
            family: Theme.fontMono
            weight: 650
            letterSpacing: -0.5
            pixelSize: 13
        }
    }

    // ── MÍDIA (título da faixa) ──
    // Row NUNCA seta a própria width (polish loop); o clamp fica só
    // no Text, que não realimenta o layout
    Row {
        id: mediaTake

        anchors.centerIn: parent
        spacing: 7
        opacity: root.lastTake === "media" ? root.mode : 0
        visible: opacity > 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.shownTitle
            color: Theme.textPrimary
            width: Math.min(implicitWidth, 170)
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 12; weight: 650 }
        }
    }

    // ── VOLUME ──
    OsdBar {
        id: volumeTake

        anchors.centerIn: parent
        opacity: root.lastTake === "volume" ? root.mode : 0
        visible: opacity > 0
        pct: OsdService.volumePct
        muted: OsdService.muted
        overdriveOn: true
        icon: {
            if (OsdService.muted) return "󰝟"
            if (OsdService.volumePct >= 70) return "󰕾"
            if (OsdService.volumePct >= 30) return "󰖀"
            if (OsdService.volumePct > 0)   return "󰕿"
            return "󰸈"
        }
    }

    // ── BRILHO ──
    OsdBar {
        id: brightTake

        anchors.centerIn: parent
        opacity: root.lastTake === "brightness" ? root.mode : 0
        visible: opacity > 0
        pct: OsdService.brightnessPct
        icon: {
            if (OsdService.brightnessPct >= 66) return "󰃠"
            if (OsdService.brightnessPct >= 33) return "󰃟"
            return "󰃞"
        }
    }
}
