import QtQuick
import "../Config"

// ═══════════════════════════════════════════
//  MEDIA WAVE — Barra de progresso em ONDA.
//  Tocando: uma senoide "anda" pela largura. Pausado: a amplitude
//  cai a zero e vira uma linha reta. O já tocado é pintado com
//  accent; o resto, com a cor de trilha.
//
//  Contrato: `progress` (0→1), `playing`. O host dá width/height.
// ═══════════════════════════════════════════
Item {
    id: root

    property real progress: 0
    property bool playing: false
    property color playedColor: Theme.accent
    property color trackColor: Theme.surface
    property real waves: 3      // ciclos ao longo da largura
    property real thickness: 2

    // Fase animada (avança só enquanto toca e visível)
    property real phase: 0
    // Amplitude anima suave entre onda (tocando) e linha (pausado)
    property real amp: playing ? 1 : 0
    Behavior on amp {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 33 // ~30fps só quando precisa
        repeat: true
        running: root.playing && root.visible
        onTriggered: {
            root.phase += 0.22
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        // ARMADILHA do Canvas: ele NÃO repinta sozinho quando só o
        // tamanho muda (estica o buffer antigo) e não pinta enquanto
        // invisível — o que faz voltar mostrando lixo do tamanho
        // anterior. Repintar em toda mudança de geometria/valor.
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()

        Connections {
            target: root
            function onProgressChanged() { canvas.requestPaint() }
            function onAmpChanged() { canvas.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width
            const h = height
            if (w <= 0 || h <= 0)
                return

            const mid = h / 2
            const A = (h / 2 - root.thickness) * root.amp
            const k = (2 * Math.PI * root.waves) / w
            const px = Math.max(0, Math.min(w, w * root.progress))

            ctx.lineWidth = root.thickness
            ctx.lineJoin = "round"
            ctx.lineCap = "round"

            // Um segmento [x0,x1] da onda com uma cor
            function seg(x0, x1, color) {
                if (x1 <= x0)
                    return
                ctx.beginPath()
                ctx.strokeStyle = color
                for (let x = x0; x <= x1; x += 1) {
                    const y = mid + A * Math.sin(k * x + root.phase)
                    if (x === x0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                ctx.stroke()
            }

            seg(0, px, root.playedColor)
            seg(px, w, root.trackColor)
        }
    }
}
