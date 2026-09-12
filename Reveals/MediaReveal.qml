import QtQuick
import "../Components"
import "../Modules"
import "../Services"

// ═══════════════════════════════════════════
//  MEDIA REVEAL — O visualizer ao lado do relógio é o anchor:
//  mirar revela a mídia completa (capa + título + artista + onda de
//  progresso + seletor de fonte). Sem música tocando ele desliza pra
//  fora (width → 0).
// ═══════════════════════════════════════════
Reveal {
    id: root

    name: "media"

    // Volume/brilho tomam o centro INTEIRO — relógio E visualizer:
    // ele sai da frente e volta depois. Já o takeover de mídia é dele
    // mesmo (a música que ele visualiza), então aí fica.
    readonly property bool shouldShow: MediaService.isPlaying
        && !OsdService.showing

    panelHovered: panelHover.hovered

    clip: true
    width: shouldShow ? vis.width + 8 : 0
    height: vis.height
    opacity: shouldShow ? 1 : 0
    // Escondido de verdade quando some — senão o HoverHandler (com
    // margem) ainda dispararia o reveal ao lado do relógio
    visible: opacity > 0

    Behavior on width { SmoothedAnimation { duration: 350 } }
    Behavior on opacity { NumberAnimation { duration: Motion.quick } }

    // ── ANCHOR: o visualizer ──
    Visualizer {
        id: vis
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    // ── PANEL: o módulo Media ──
    panel: Item {
        implicitHeight: media.implicitHeight + 6

        Behavior on opacity { NumberAnimation { duration: Motion.quick } }

        HoverHandler { id: panelHover }

        Media {
            id: media
            anchors.left: parent.left
            anchors.top: parent.top
        }
    }
}
