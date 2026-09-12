import QtQuick
import "../Config"
import "../Services"

// ═══════════════════════════════════════════
//  VISUALIZER — Barrinhas "dançando" quando há música.
//  Decorativo: é aleatório, não lê o áudio de verdade.
// ═══════════════════════════════════════════
Row {
    id: root

    spacing: 2.5
    height: 13

    readonly property bool isPlaying: MediaService.isPlaying

    opacity: isPlaying ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        Smooth {}
    }

    // Cada barra tem timing levemente diferente pra parecer orgânico
    Repeater {
        model: [
            { interval: 220, initH: 13, dur: 200 },
            { interval: 170, initH: 8,  dur: 150 },
            { interval: 260, initH: 11, dur: 240 },
            { interval: 190, initH: 6,  dur: 170 }
        ]

        Rectangle {
            required property var modelData

            width: 2.5
            radius: 1.2
            anchors.bottom: parent.bottom
            color: Theme.accent
            height: root.isPlaying ? modelData.initH : 3

            Behavior on height {
                NumberAnimation { duration: modelData.dur; easing.type: Easing.OutCubic }
            }

            Timer {
                interval: modelData.interval
                running: root.isPlaying
                repeat: true
                onTriggered: parent.height = Math.max(3, Math.random() * 13)
            }
        }
    }
}
