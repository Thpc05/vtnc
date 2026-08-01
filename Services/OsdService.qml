pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../Components"

// ═══════════════════════════════════════════
//  OSD SERVICE — Estado dos OSDs de volume e brilho num lugar só.
//
//  O OSD é conteúdo, não rosto: aqui mora o valor e quem pede o
//  centro; quem desenha é o Module Center. Com o estado fora da UI,
//  os listeners (PwObjectTracker, polling do backlight) vivem UMA
//  vez — presos ao dado, não a quem o mostra.
//
//  Volume e brilho se atropelam (o último a mudar ganha o centro);
//  a prioridade contra a mídia é decidida no Center.
// ═══════════════════════════════════════════
Singleton {
    id: root

    // "none" | "volume" | "brightness" — o que quer o centro agora
    property string active: "none"
    readonly property bool showing: active !== "none"

    // ── VOLUME ──
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volumeRaw: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // Driver do slider: a barra E a largura derivam DESTE valor
    // animado — impossível dessincronizar, mesmo com o botão preso
    property real shownVolume: 0
    Behavior on shownVolume {
        NumberAnimation { duration: Theme.osdTrackDuration; easing.type: Easing.OutCubic }
    }
    readonly property int volumePct: Math.round(shownVolume * 100)

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    onVolumeRawChanged: {
        shownVolume = volumeRaw
        if (ready) show("volume")
    }
    onMutedChanged: if (ready) show("volume")

    // ── BRILHO ──
    // sysfs não emite inotify: relê por polling leve. Mudou, aparece.
    readonly property int rawCurrent: parseInt(curFile.text()) || 0
    readonly property int rawMax: parseInt(maxFile.text()) || 1
    readonly property int brightnessRaw:
        Math.min(100, Math.round(rawCurrent / rawMax * 100))

    property real shownBrightness: 0
    Behavior on shownBrightness {
        NumberAnimation { duration: Theme.osdTrackDuration; easing.type: Easing.OutCubic }
    }
    readonly property int brightnessPct: Math.round(shownBrightness)

    FileView { id: curFile; path: Config.backlightFile }
    FileView { id: maxFile; path: Config.backlightMaxFile }

    Timer {
        interval: Config.backlightPollMs
        running: true
        repeat: true
        onTriggered: curFile.reload()
    }

    onBrightnessRawChanged: {
        shownBrightness = brightnessRaw
        if (ready) show("brightness")
    }

    // ── AUTO-HIDE ──
    // Ignora os valores iniciais do startup (senão o shell nasce
    // mostrando um OSD que ninguém pediu)
    property bool ready: false
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }

    Timer {
        id: hideTimer
        interval: Config.osdTimeout
        onTriggered: root.active = "none"
    }

    function show(name) {
        active = name
        hideTimer.restart()
    }
    function hide() {
        active = "none"
        hideTimer.stop()
    }
}
