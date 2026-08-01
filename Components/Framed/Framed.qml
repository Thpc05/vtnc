import ".."
import "../Pill"
import QtQuick
import "../../Reveals"

// ═══════════════════════════════════════════
//  FRAMED — Barra de topo INDEPENDENTE, camada por baixo da pill.
//  A pill não sabe que ela existe: segue fazendo apps, dashboard, OSD
//  e mídia por cima. A framed só acrescenta uma faixa no topo com
//  widgets nos cantos, e cada widget revela uma BOLHA que emerge da
//  barra (estilo caelestia).
//
//  Reusa os 5 reveals da pill (mesmo contrato Reveal: anchor + panel).
//  Instâncias PRÓPRIAS — um reveal é um item visual com posição, não
//  dá pra compartilhar entre janelas. Como a pill wide desliga quando
//  a framed está on, nunca há dois hosts do mesmo reveal ativos.
//
//  Preenche a janela (full-screen anchored, transparente). Só a faixa
//  e a bolha ativa recebem clique (via `hitAreas` → mask do shell).
// ═══════════════════════════════════════════
Item {
    id: root

    // Onde a barra aceita clique: a faixa + a bolha ativa
    readonly property list<Item> hitAreas: [bar, bubble]

    readonly property real barBottom: Framed_Theme.height
    // Alinha os widgets dos cantos com a faixa da pill (não com o
    // centro da barra, que desce mais por causa do framedMarginDown)
    readonly property real bandCenter: Pill_Theme.marginTop + Pill_Theme.height / 2

    // ═══════════════════════════════════════════
    //  REVEALS — registro. Anchor declarado onde vive; a lista liga
    //  os painéis à bolha. Adicionar = criar arquivo + anchor + id.
    // ═══════════════════════════════════════════
    readonly property list<Item> reveals: [ws, trayReveal, batteryReveal, notifReveal, mediaReveal]

    // Reveal mirado agora (autoShow (notificação) não espera hover)
    readonly property Item hoveredReveal: {
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].autoShow)
                return reveals[i]
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].revealed)
                return reveals[i]
        return null
    }

    // Mostrado — segue o mirado com grace pro mouse cruzar do widget
    // até a bolha sem ela fechar no meio do caminho
    property Item shownReveal: null
    onHoveredRevealChanged: {
        if (hoveredReveal) {
            shownReveal = hoveredReveal
            bubbleCloseTimer.stop()
        } else {
            bubbleCloseTimer.restart()
        }
    }
    Timer {
        id: bubbleCloseTimer
        interval: Framed_Theme.bubbleGrace
        onTriggered: root.shownReveal = null
    }

    // Centro do widget mirado em coordenadas da barra (pra bolha se
    // alinhar nele). mapToItem não é reativo — as leituras abaixo é que
    // fazem reavaliar quando o layout muda
    readonly property real bubbleCenter: {
        const r = shownReveal
        if (!r)
            return lastCenter // fechando: segura o último, não salta pro canto
        void root.width
        void r.x
        void r.width
        void leftCluster.x
        void rightCluster.x
        void rightCluster.width
        return r.mapToItem(root, r.width / 2, 0).x
    }
    // Guarda o último centro mirado: com a bolha fechada, bubbleCenter
    // volta pra cá em vez de 0 — assim a bolha não desliza do canto
    // esquerdo ao abrir; e ENTRE reveals ela morfa (x/largura animam)
    property real lastCenter: width / 2
    onBubbleCenterChanged: if (shownReveal) lastCenter = bubbleCenter

    // ═══════════════════════════════════════════
    //  A FAIXA
    // ═══════════════════════════════════════════
    Rectangle {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Framed_Theme.height
        color: Framed_Theme.barColor

        // Clique no fundo VAZIO da barra alterna a dashboard (mesmo
        // gesto da pill; hit-test manual descarta cliques nos widgets)
        TapHandler {
            onTapped: eventPoint => {
                const p = eventPoint.position
                for (const b of [leftCluster, rightCluster]) {
                    const l = bar.mapToItem(b, p.x, p.y)
                    if (l.x >= 0 && l.x <= b.width && l.y >= 0 && l.y <= b.height)
                        return
                }
                root.backgroundTapped()
            }
        }

        // ── CANTO ESQUERDO: workspaces ──
        Item {
            id: leftCluster

            anchors.left: parent.left
            anchors.leftMargin: Framed_Theme.contentMargin
            anchors.verticalCenter: parent.top
            anchors.verticalCenterOffset: root.bandCenter
            width: childrenRect.width
            height: childrenRect.height

            WorkspaceReveal { id: ws }
        }

        // ── CANTO DIREITO: tray · bateria · sino · mídia ──
        Row {
            id: rightCluster

            anchors.right: parent.right
            anchors.rightMargin: Framed_Theme.contentMargin
            anchors.verticalCenter: parent.top
            anchors.verticalCenterOffset: root.bandCenter
            spacing: 14

            TrayReveal { id: trayReveal; anchors.verticalCenter: parent.verticalCenter }
            BatteryReveal { id: batteryReveal; anchors.verticalCenter: parent.verticalCenter }
            NotifReveal { id: notifReveal; anchors.verticalCenter: parent.verticalCenter }
            MediaReveal { id: mediaReveal; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // Cantos CÔNCAVOS da base da barra — a faixa curva pra dentro da
    // tela onde encontra as laterais. O vazio do recorte fica pra
    // BAIXO (pra dentro da tela): esquerda carve bottom-right (rot 0),
    // direita carve bottom-left (rot 90)
    ConcaveCorner {
        radius: Framed_Theme.cornerRadius
        fillColor: Framed_Theme.barColor
        rotation: 0
        x: 0
        y: root.barBottom
    }
    ConcaveCorner {
        radius: Framed_Theme.cornerRadius
        fillColor: Framed_Theme.barColor
        rotation: 90
        x: root.width - width
        y: root.barBottom
    }

    // ═══════════════════════════════════════════
    //  A BOLHA — o painel que emerge da barra ao mirar um widget.
    //  Um corpo só, que troca de conteúdo e se realinha no widget.
    //  A altura animando É o que faz a bolha "sair" da barra.
    // ═══════════════════════════════════════════
    Rectangle {
        id: bubble

        readonly property real pad: Framed_Theme.bubblePad

        // Morfa como a pill: largura e posição animam (entre reveals
        // ela desliza/redimensiona), mas SEM saltar do canto ao abrir —
        // o lastCenter segura a origem. x acopla na borda da tela
        // quando o widget está muito perto (o clamp faz o encaixe)
        width: root.shownReveal ? root.shownReveal.panelWidth + pad * 2 : 0
        height: root.shownReveal ? root.shownReveal.panelHeight + pad * 2 : 0
        x: Math.max(Framed_Theme.contentMargin,
            Math.min(root.width - width - Framed_Theme.contentMargin,
                root.bubbleCenter - width / 2))
        y: root.barBottom
        // Emenda na barra em cima; cantos arredondados só embaixo
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Framed_Theme.bubbleRadius
        bottomRightRadius: Framed_Theme.bubbleRadius
        color: Framed_Theme.barColor
        clip: true
        visible: height > 0.5

        // A altura faz a bolha "descer" da barra; largura/x morfam
        // entre reveals (mesma duração/easing = um movimento só)
        Behavior on height {
            NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
        }
        Behavior on width {
            NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
        }
        Behavior on x {
            NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
        }

        Item {
            id: bubbleHost
            anchors.fill: parent
            anchors.margins: bubble.pad
            clip: true
        }
    }

    // ── SOLDA (welding) entre a bolha e a barra ──
    // Cantos côncavos nos DOIS lados do topo da bolha: a faixa flui
    // pra dentro da bolha, como se ela brotasse dali (não um retângulo
    // colado). Seguem o x da bolha (que anima) e crescem com ela.
    // Esquerda carve bottom-left (rot 90), direita carve bottom-right
    // (rot 0) — o oposto dos cantos da barra, pra fechar PRA DENTRO
    ConcaveCorner {
        radius: Math.min(Framed_Theme.weldRadius, bubble.height)
        fillColor: Framed_Theme.barColor
        rotation: 90
        x: bubble.x - width
        y: root.barBottom
        visible: bubble.visible && radius >= 1
    }
    ConcaveCorner {
        radius: Math.min(Framed_Theme.weldRadius, bubble.height)
        fillColor: Framed_Theme.barColor
        rotation: 0
        x: bubble.x + bubble.width
        y: root.barBottom
        visible: bubble.visible && radius >= 1
    }

    // Clique no fundo vazio da barra (o shell conecta em toggleDashboard)
    signal backgroundTapped()

    // Wiring pelo contrato: cada painel reparentado pra bolha, na
    // largura natural do reveal (panelWidth). Aparece quando é o
    // mostrado
    Component.onCompleted: {
        for (let i = 0; i < reveals.length; i++) {
            const r = reveals[i]
            if (!r.panel)
                continue
            r.panel.parent = bubbleHost
            r.panel.anchors.top = bubbleHost.top
            r.panel.anchors.left = bubbleHost.left
            r.panel.anchors.right = bubbleHost.right
            r.panel.opacity = Qt.binding(() => root.shownReveal === r ? 1 : 0)
            r.panel.visible = Qt.binding(() => r.panel.opacity > 0)
        }
    }
}
