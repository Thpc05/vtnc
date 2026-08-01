import ".."
import "."
import QtQuick
import "../../Modules"
import "../../Reveals"
import "../../Services"

// ═══════════════════════════════════════════
//  BAR — A face padrão da ilha, com dois drivers ortogonais:
//
//  `wide` (0 → 1): pill normal ↔ pill wide.
//    Normal: visualizer + relógio.
//    Wide:   workspaces | (normal) | cluster de reveals.
//    Dirigido por hover, por Persist.wideBar (IPC `pill`), ou por um
//    reveal que se abre sozinho.
//
//  `revealHeight`: os hover-reveals do cluster. A Bar não conhece
//  nenhum reveal concreto — só o contrato Reveal (anchor + panel),
//  mesmo padrão Pill ↔ PillFace.
//
//  `expand` (0 → 1): idle → dashboard. SÓ via IPC (hover não abre).
//
//  Tamanhos e opacidades derivam dos drivers — nada dessincroniza.
// ═══════════════════════════════════════════
PillFace {
    id: root

    name: "bar"
    role: "bar"

    // Setado pela Pill (o IPC força a dashboard)
    property bool forceExpand: false

    // Dashboard aberta com um widget pedindo teclado (senha do wifi)
    readonly property bool dashKeyboard: forceExpand && dash.wantsKeyboard

    // Emitido quando o FUNDO da linha de topo é clicado
    // (a Pill conecta em toggleDashboard)
    signal backgroundTapped()

    readonly property real sidePad: Theme.contentPadding + 4

    // Algum reveal se abrindo sozinho (notificação chegando)? Ele mora
    // no cluster, que só existe na wide — então a wide abre junto,
    // senão a notificação não teria onde nascer
    readonly property bool autoReveal: {
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].autoShow)
                return true
        return false
    }

    // ── DRIVER do modo wide ──
    // Com a framed ligada a pill fica normal: os workspaces/cluster e
    // os reveals migram pra barra de topo (a notificação também nasce
    // lá). Sem a framed, é a wide de sempre.
    readonly property bool wideOn: !Persist.state.framed
        && (Persist.state.wideBar || hover.hovered || autoReveal)
    // Regra de negócio: ao sair da wide, PRIMEIRO o reveal fecha
    // (revealHeight → 0), só então a pill contrai
    property real wide: (wideOn || revealHeight > 0) ? 1 : 0
    Behavior on wide {
        NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
    }
    // Conteúdo da wide entra na 2ª metade: nunca vaza da pill estreita
    readonly property real lateWide: Math.max(0, wide * 2 - 1)

    // ── DRIVER da dashboard ──
    property real expand: forceExpand ? 1 : 0
    Behavior on expand {
        // Tempo PRÓPRIO (não o expandDuration): a dashboard tem o peso
        // de uma troca de face e precisa acompanhar os apps
        NumberAnimation { duration: Theme.dashDuration; easing.type: Easing.OutQuart }
    }
    // Conteúdo da dashboard aparece na 2ª metade da expansão (e some
    // na 1ª metade do colapso — nunca vaza da pill)
    readonly property real lateExpand: Math.max(0, expand * 2 - 1)
    // Conteúdo do modo wide: visível na wide E na dashboard — o topo
    // da dashboard É a pill wide
    readonly property real wideContent: Math.max(lateWide * (1 - expand), lateExpand)

    // ═══════════════════════════════════════════
    //  REVEALS — registro. O anchor é declarado onde ele vive
    //  (cluster direito ou centro); esta lista só liga os painéis.
    //  Adicionar um = criar arquivo + declarar o anchor + 1 id aqui.
    // ═══════════════════════════════════════════
    readonly property list<Item> reveals: [
        ws,
        mediaReveal,
        batteryReveal,
        trayReveal,
        notifReveal
    ]

    // Regra de negócio: reveals só armam com a wide aberta + um
    // respiro. Sem isso, mirar a borda da pill normal faz os anchors
    // varrerem por baixo do mouse durante o morph e o reveal pisca.
    property bool revealsArmed: false
    onWideOnChanged: {
        if (wideOn) {
            revealArmTimer.restart()
        } else {
            revealArmTimer.stop()
            revealsArmed = false
        }
    }
    Timer {
        id: revealArmTimer
        interval: Theme.expandDuration + 120
        onTriggered: root.revealsArmed = true
    }

    // Reveal mirado agora (cru; null enquanto desarmado)
    readonly property Item hoveredReveal: {
        // autoShow não espera armar: é explícito, não é o mouse
        // passeando pela borda durante o morph
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].autoShow)
                return reveals[i]
        if (!revealsArmed)
            return null
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].revealed)
                return reveals[i]
        return null
    }

    // Reveal mostrado — segue o mirado com um grace period no fechar,
    // pro mouse cruzar do anchor até o painel sem colapsar no meio.
    // Fora da pill não tem travessia: fecha na hora (é o que dispara
    // a sequência reveal fecha → wide contrai)
    property Item shownReveal: null
    onHoveredRevealChanged: {
        if (hoveredReveal) {
            shownReveal = hoveredReveal
            revealCloseTimer.stop()
        } else if (!hover.hovered) {
            revealCloseTimer.stop()
            shownReveal = null
        } else {
            revealCloseTimer.restart()
        }
    }
    Timer {
        id: revealCloseTimer
        interval: 250
        onTriggered: root.shownReveal = null
    }

    // Altura extra do painel revelado
    property real revealHeight: shownReveal ? shownReveal.panelHeight + 10 : 0
    Behavior on revealHeight {
        NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
    }

    // Wiring pelo contrato: panels reparentados pro host. O painel
    // SEMPRE estica na pill — é o jeito da ilha
    Component.onCompleted: {
        // Nasceu já em modo wide (persistido)? Arma os reveals
        if (wideOn)
            revealArmTimer.start()
        for (let i = 0; i < reveals.length; i++) {
            const r = reveals[i]
            if (!r.panel)
                continue
            r.panel.parent = revealHost
            r.panel.anchors.top = revealHost.top
            r.panel.anchors.left = revealHost.left
            r.panel.anchors.right = revealHost.right
            r.panel.opacity = Qt.binding(() => root.shownReveal === r ? 1 : 0)
            r.panel.visible = Qt.binding(() => r.panel.opacity > 0)
        }
    }

    // ═══════════════════════════════════════════
    //  TAMANHO
    // ═══════════════════════════════════════════
    // Folga por workspace além de 5. São 30 e não 15 porque o relógio
    // é centralizado: o espaço à esquerda dele só cresce METADE do que
    // a pill cresce — 2 × 15px/dot mantém a folga simétrica
    property real wideExtra: Math.max(0, ws.count - 5) * 30
    Behavior on wideExtra {
        NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
    }

    // Normal: mínimo do Pill_Theme, cresce se o miolo não couber
    readonly property real normalW: Math.max(
        Pill_Theme.width, centerRow.implicitWidth + sidePad * 2)
    // Wide: base fixa (workspaces e cluster têm lugar garantido) mais
    // o que o miolo pede além do relógio — senão o título da faixa
    // ficaria espremido entre os dois clusters
    readonly property real wideW:
        Pill_Theme.wideWidth + Pill_Theme.width + wideExtra + clock.extraWidth

    readonly property real idleW: normalW + (wideW - normalW) * wide
    readonly property real idleH:
        Pill_Theme.height + (Pill_Theme.wideHeight - Pill_Theme.height) * wide

    // A dashboard sobrepõe os dois: a largura dela é dinâmica (cresce
    // quando um widget expande além do piso base) e a pill acompanha
    contentWidth: idleW
        + (dash.width + Theme.contentPadding * 2 - idleW) * expand
    contentHeight: idleH + revealHeight
        + (Theme.dashTopHeight + dash.implicitHeight + Theme.contentPadding - idleH) * expand

    HoverHandler { id: hover }

    // ═══════════════════════════════════════════
    //  LINHA PRINCIPAL — idle ocupa tudo; com a dashboard aberta vira
    //  a "title bar" dela (o mesmo conteúdo da pill wide)
    // ═══════════════════════════════════════════
    Item {
        id: topRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.idleH + (Theme.dashTopHeight - root.idleH) * root.expand

        // Clique no fundo VAZIO alterna a dashboard. Hit-test manual:
        // cliques sobre o conteúdo não contam (o TapHandler não toma
        // grab exclusivo, então tudo chega aqui). O painel do reveal
        // fica de fora por estar abaixo do topRow
        TapHandler {
            onTapped: eventPoint => {
                const p = eventPoint.position
                for (const b of [ws, centerRow, anchorRow]) {
                    if (!b.visible)
                        continue
                    const l = topRow.mapToItem(b, p.x, p.y)
                    if (l.x >= 0 && l.x <= b.width && l.y >= 0 && l.y <= b.height)
                        return
                }
                root.backgroundTapped()
            }
        }

        // ── WIDE: workspaces (esquerda). Os dots são o anchor do
        //  WorkspaceReveal, o único do cluster esquerdo ──
        WorkspaceReveal {
            id: ws

            anchors.left: parent.left
            anchors.leftMargin: root.sidePad
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.wideContent
            visible: opacity > 0
        }

        // ── O MIOLO: visualizer + relógio ──
        Row {
            id: centerRow

            anchors.centerIn: parent
            spacing: 0

            // Visualizer: é o anchor do MediaReveal e desliza pra fora
            // quando não há música
            MediaReveal {
                id: mediaReveal
                anchors.verticalCenter: parent.verticalCenter
            }

            // Relógio, ou quem estiver tomando o centro (OSD de
            // volume/brilho, título da faixa)
            Center {
                id: clock
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── WIDE: cluster de reveals (direita) ──
        Row {
            id: anchorRow

            anchors.right: parent.right
            anchors.rightMargin: root.sidePad
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            opacity: root.wideContent
            visible: opacity > 0

            TrayReveal { id: trayReveal }
            // Bateria de emergência (< Config.batteryWarnLevel): mora
            // entre o tray e as notificações. Some sozinha acima disso
            BatteryReveal { id: batteryReveal }
            NotifReveal { id: notifReveal }
        }
    }

    // ═══════════════════════════════════════════
    //  HOST DOS PAINÉIS REVELADOS (abaixo da linha principal).
    //  Os panels são reparentados pra cá pelo wiring; a altura segue
    //  o driver revealHeight (o clip segura o resto)
    // ═══════════════════════════════════════════
    Item {
        id: revealHost

        anchors.top: topRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.contentPadding
        anchors.rightMargin: Theme.contentPadding
        height: root.revealHeight
        clip: true
    }

    // ═══════════════════════════════════════════
    //  DASHBOARD — quebra-cabeça de widgets.
    //  Ancorada no revealHost: reveal aberto empurra o grid
    //  (ordem vertical: pill wide → reveal → dashboard)
    // ═══════════════════════════════════════════
    Dashboard {
        id: dash

        anchors.top: revealHost.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        // Piso mínimo — widget em posição além dele faz a dashboard
        // (e a pill, via contentWidth) crescer pra acomodar
        baseWidth: Theme.dashWidth - Theme.contentPadding * 2
        // Fade do conteúdo: segue o morph (sem Behavior próprio), mas o
        // PONTO de início é uma variável. Menor `dashContentStart` =
        // entra antes e sobe mais gradual (menos "pipoca")
        opacity: Theme.lateReveal(root.expand, Theme.dashContentStart)
        visible: opacity > 0
    }
}
