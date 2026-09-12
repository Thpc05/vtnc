import QtQuick
import Quickshell.Services.Pipewire
import ".."
import "../../Config"

// ═══════════════════════════════════════════
//  VOLUME WIDGET — Volume geral, dispositivos e mixer por app.
//  Idle: ícone (clique muta) + slider geral + %.
//  Expandido: três colunas — IN (entrada), OUT (saída) e APPS
//  (mixer por aplicativo, um mini-slider por stream).
//
//  TODO: expansão lateral prevista e DESLIGADA. O plano era
//  `sizeExpand: "full"` + `expandDir: "down-both"` (crescer pros dois
//  lados, centrado); hoje é big/down, então as três colunas se
//  espremem em 4 subcolunas. A Dashboard já sabe fazer (leftGrow +
//  normalização de coluna negativa) — é só ligar e testar.
//
//  Tamanhos: big/full · direções: down, down-left/right, down-both.
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "audio"
    sizeIdle: "big"        // Big and Full
    sizeExpand: "big"     // Big and Full
    expandDir: "down" // down, down-left, down-right and down-both

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volumePct: Math.round(volume * 100)

    // Dispositivos reais (nós de hardware, não streams de apps)
    readonly property var outputs: Pipewire.nodes.values.filter(
        n => n.isSink && !n.isStream && n.audio)
    readonly property var inputs: Pipewire.nodes.values.filter(
        n => !n.isSink && !n.isStream && n.audio)
    // Streams de apps TOCANDO áudio (mixer) — isStream && isSink
    // confirmado por probe (ex: node "Zen")
    readonly property var streams: Pipewire.nodes.values.filter(
        n => n.isStream && n.isSink && n.audio)

    PwObjectTracker {
        objects: [...root.outputs, ...root.inputs, ...root.streams]
    }

    function nodeLabel(n) {
        return n.nickname || n.description || n.name
    }

    readonly property string icon: {
        if (muted) return "󰝟"
        if (volumePct >= 70) return "󰕾"
        if (volumePct >= 30) return "󰖀"
        if (volumePct > 0)   return "󰕿"
        return "󰸈"
    }

    // ── HEADER: ícone (clique muta) + slider geral + dado (%) ──
    //  O slider vive no header → aparece JÁ no idle (e continua no
    //  expandido). O bloco de baixo é só IN | OUT | APPS.
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerH

        Item {
            id: muteBox

            width: 24
            height: 22
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusChip
                color: muteHover.hovered ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.expanded ? Theme.accent : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 16 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            HoverHandler { id: muteHover }
            TapHandler {
                onTapped: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted
                }
            }
        }

        Text {
            id: pctText

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "mute" : `${root.volumePct}%`
            color: Theme.textSecondary
            font { family: Theme.fontMono; pixelSize: 11 }
        }

        // Slider geral (arrastável; 0 → 100%) — entre o ícone e o %
        Item {
            anchors.left: muteBox.right
            anchors.leftMargin: 10
            anchors.right: pctText.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 16

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 5
                radius: 2.5
                color: Theme.surface
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Math.min(1, root.volume)
                height: 5
                radius: 2.5
                color: root.muted ? Theme.textMuted : Theme.accent
            }

            MouseArea {
                anchors.fill: parent
                // O DragHandler do widget (mover peça) não pode roubar
                // o grab no meio do arrasto do slider
                preventStealing: true

                function apply(mx) {
                    if (!root.sink?.audio) return
                    root.sink.audio.volume =
                        Math.max(0, Math.min(1, mx / width))
                }

                onPressed: mouse => apply(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed) apply(mouse.x)
                }
            }
        }
    }

    // ── EXPANDIDO: IN | OUT | APPS ──
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 10
        opacity: root.lateReveal
        visible: opacity > 0

        // IN | OUT | APPS
        Row {
            width: parent.width
            spacing: 12

            // ── IN (entrada) ──
            Column {
                width: (parent.width - 24) / 3
                spacing: 3

                Text {
                    text: "IN"
                    color: Theme.textMuted
                    font { family: Theme.fontMono; pixelSize: 9; weight: 700; letterSpacing: 1 }
                }

                ListView {
                    width: parent.width
                    height: 74
                    clip: true
                    spacing: 2
                    model: root.inputs

                    delegate: Item {
                        id: inItem

                        required property var modelData

                        readonly property bool current:
                            root.source && modelData.id === root.source.id

                        width: ListView.view.width
                        height: 18

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusChip
                            color: inHover.hovered ? Theme.hoverLayer : "transparent"
                            Behavior on color { ColorAnimation { duration: Motion.instant } }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.nodeLabel(inItem.modelData)
                            color: inItem.current ? Theme.accent : Theme.textSecondary
                            elide: Text.ElideRight
                            font { family: Theme.fontDisplay; pixelSize: 11 }
                            Behavior on color { ColorAnimation { duration: Motion.instant } }
                        }

                        HoverHandler { id: inHover }
                        TapHandler {
                            onTapped: Pipewire.preferredDefaultAudioSource = inItem.modelData
                        }
                    }
                }
            }

            // ── OUT (saída) ──
            Column {
                width: (parent.width - 24) / 3
                spacing: 3

                Text {
                    text: "OUT"
                    color: Theme.textMuted
                    font { family: Theme.fontMono; pixelSize: 9; weight: 700; letterSpacing: 1 }
                }

                ListView {
                    width: parent.width
                    height: 74
                    clip: true
                    spacing: 2
                    model: root.outputs

                    delegate: Item {
                        id: outItem

                        required property var modelData

                        readonly property bool current:
                            root.sink && modelData.id === root.sink.id

                        width: ListView.view.width
                        height: 18

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusChip
                            color: outHover.hovered ? Theme.hoverLayer : "transparent"
                            Behavior on color { ColorAnimation { duration: Motion.instant } }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.nodeLabel(outItem.modelData)
                            color: outItem.current ? Theme.accent : Theme.textSecondary
                            elide: Text.ElideRight
                            font { family: Theme.fontDisplay; pixelSize: 11 }
                            Behavior on color { ColorAnimation { duration: Motion.instant } }
                        }

                        HoverHandler { id: outHover }
                        TapHandler {
                            onTapped: Pipewire.preferredDefaultAudioSink = outItem.modelData
                        }
                    }
                }
            }

            // ── APPS (mixer por aplicativo) ──
            Column {
                width: (parent.width - 24) / 3
                spacing: 3

                Text {
                    text: "APPS"
                    color: Theme.textMuted
                    font { family: Theme.fontMono; pixelSize: 9; weight: 700; letterSpacing: 1 }
                }

                ListView {
                    width: parent.width
                    height: 74
                    clip: true
                    spacing: 4
                    model: root.streams

                    // Vazio: nenhum app tocando
                    Text {
                        anchors.centerIn: parent
                        visible: root.streams.length === 0
                        text: "Nenhum app"
                        color: Theme.textMuted
                        font { family: Theme.fontDisplay; pixelSize: 10 }
                    }

                    delegate: Item {
                        id: appItem

                        required property var modelData

                        readonly property real appVol: modelData.audio?.volume ?? 0
                        readonly property bool appMuted: modelData.audio?.muted ?? false

                        width: ListView.view.width
                        height: 24

                        // Nome do app (clique muta/desmuta o stream)
                        Text {
                            id: appName

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: root.nodeLabel(appItem.modelData)
                            color: appItem.appMuted ? Theme.textMuted : Theme.textSecondary
                            elide: Text.ElideRight
                            font { family: Theme.fontDisplay; pixelSize: 10 }
                            Behavior on color { ColorAnimation { duration: Motion.instant } }

                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: {
                                    if (appItem.modelData.audio)
                                        appItem.modelData.audio.muted = !appItem.modelData.audio.muted
                                }
                            }
                        }

                        // Mini-slider do stream
                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 10

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 3
                                radius: 1.5
                                color: Theme.surface
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * Math.min(1, appItem.appVol)
                                height: 3
                                radius: 1.5
                                color: appItem.appMuted ? Theme.textMuted : Theme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true

                                function apply(mx) {
                                    if (!appItem.modelData.audio) return
                                    appItem.modelData.audio.volume =
                                        Math.max(0, Math.min(1, mx / width))
                                }

                                onPressed: mouse => apply(mouse.x)
                                onPositionChanged: mouse => {
                                    if (pressed) apply(mouse.x)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
