import QtQuick
import Quickshell.Services.Pipewire
import "."
import "../../Config"

// ═══════════════════════════════════════════
//  VOLUME CARD — O slider de som.
//  FALTA a escolha de saída/entrada e o mixer por app (ver a nota
//  no WifiCard).
// ═══════════════════════════════════════════
SliderCard {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0

    // Sem o tracker o volume não atualiza sozinho quando muda por fora
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    value: vol
    muted: sink?.audio?.muted ?? false

    icon: {
        if (muted) return "󰝟"
        const p = Math.round(vol * 100)
        if (p >= 70) return "󰕾"
        if (p >= 30) return "󰖀"
        if (p > 0)   return "󰕿"
        return "󰸈"
    }

    onCommit: v => {
        if (!sink?.audio)
            return
        // Mexer no slider tira o mudo: arrastar e não ouvir nada é o
        // tipo de coisa que faz parecer quebrado
        if (sink.audio.muted && v > 0)
            sink.audio.muted = false
        sink.audio.volume = v
    }
}
