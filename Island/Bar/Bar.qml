import ".."
import "../../ConfigValues"
import "../../Services"
import "../../Ui"
import QtQuick

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
//  mesmo padrão Island ↔ IslandFace.
//
//  A control center NÃO mora mais aqui. Ela virou uma face de app
//  (ControlCenter/ControlCenter.qml) e a ilha MORFA nela, como faz com o
//  launcher. Antes ela crescia pra baixo dentro desta face, o que
//  fazia o relógio, os workspaces e o cluster de reveals ficarem
//  pendurados em cima dela — um Control Center não é continuação da
//  barra. Com isso saíram daqui o driver `expand`, o `forceExpand`, o
//  `lateExpand` e o repasse de teclado.
//
//  Tamanhos e opacidades derivam dos drivers — nada dessincroniza.
// ═══════════════════════════════════════════
IslandFace {
    id: root

    name: "bar"
    role: "bar"

    // Emitido quando o FUNDO da linha de topo é clicado
    // (a Island conecta em abrir a control center)
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
    // `revealGroup.open` entra aqui por causa do grace: tirar o mouse
    // da ilha não fecha o reveal na hora, e sem este termo a wide
    // colapsaria sozinha durante a espera — a pill ficaria estreita E
    // alta por ~meio segundo. Com ele, os dois seguram e SOLTAM no
    // mesmo instante (quando o grace expira)
    readonly property bool wideOn:
        Persist.state.wideBar || hover.hovered || autoReveal || revealGroup.open
    // Sair da wide com um reveal aberto é UM movimento só: `wide` e
    // `revealHeight` caem juntos (mesma duração/easing), então a pill
    // contrai em largura e altura ao mesmo tempo. NÃO condicionar isto
    // a `revealHeight > 0` — o reveal fecharia primeiro e a pill
    // passaria pela wide antes de virar normal (morph em dois tempos)
    property real wide: wideOn ? 1 : 0
    Behavior on wide {
        Settle {}
    }
    // Conteúdo da wide entra na 2ª metade: nunca vaza da pill estreita
    readonly property real lateWide: Math.max(0, wide * 2 - 1)


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

    // Reveal mirado agora (cru). O autoShow (notificação chegando) tem
    // prioridade: é explícito, não é o mouse passeando
    readonly property Item hoveredReveal: {
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].autoShow)
                return reveals[i]
        for (let i = 0; i < reveals.length; i++)
            if (reveals[i].revealed)
                return reveals[i]
        return null
    }

    // ── AS ESPERAS ──
    // O openDelay do grupo é o que substituiu o antigo `revealsArmed`:
    // aquilo era um timer que desabilitava os reveals durante o morph
    // da wide, porque os anchors varrem por baixo do mouse enquanto a
    // pill cresce e o reveal piscava. Com a espera, um anchor que
    // passa sob o cursor nunca acumula os 350ms — o sintoma some sem
    // precisar de estado extra. E as duas esperas NÃO se somam: armar
    // + delay dariam ~800ms até o primeiro reveal, que parece travado.
    HoverGroup {
        id: revealGroup
        candidate: root.hoveredReveal
    }
    readonly property Item shownReveal: revealGroup.shown

    // Sair da ilha NÃO fecha na hora: cai no closeGrace do grupo, pro
    // painel não sumir no instante em que o mouse escapa da borda
    onHoveredRevealChanged: {
        if (hoveredReveal && hoveredReveal.autoShow)
            revealGroup.openNow(hoveredReveal) // explícito: não espera
    }

    // Altura extra do painel revelado
    property real revealHeight: shownReveal ? shownReveal.panelHeight + 10 : 0
    Behavior on revealHeight {
        Settle {}
    }
    // O Settle passa do alvo nos DOIS sentidos: ao fechar, revealHeight
    // mergulha abaixo de zero. Isso daria altura negativa no host, e a
    // barra inteira pinçaria — 7px de mergulho numa faixa de 32px é 22%
    // da altura, lido como glitch, não como peso. A control center PODE
    // pinçar (398px de curso, o mergulho é proporcional e parece peso);
    // a barra não tem essa folga. Todo consumidor usa o valor preso
    readonly property real revealH: Math.max(0, revealHeight)

    // Wiring pelo contrato: panels reparentados pro host. O painel
    // SEMPRE estica na pill — é o jeito da ilha
    Component.onCompleted: {
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
        Settle {}
    }

    // Normal: mínimo do IslandTheme, cresce se o miolo não couber
    readonly property real normalW: Math.max(
        IslandTheme.width, centerRow.implicitWidth + sidePad * 2)
    // Wide: base fixa (workspaces e cluster têm lugar garantido) mais
    // o que o miolo pede além do relógio — senão o título da faixa
    // ficaria espremido entre os dois clusters
    readonly property real wideW:
        IslandTheme.wideWidth + IslandTheme.width + wideExtra + clock.extraWidth

    readonly property real idleW: normalW + (wideW - normalW) * wide
    readonly property real idleH:
        IslandTheme.height + (IslandTheme.wideHeight - IslandTheme.height) * wide

    contentWidth: idleW
    contentHeight: idleH + revealH

    HoverHandler { id: hover }

    // ═══════════════════════════════════════════
    //  LINHA PRINCIPAL — a barra em si
    // ═══════════════════════════════════════════
    Item {
        id: topRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.idleH

        // Clique no fundo VAZIO abre a control center. Hit-test manual:
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
            opacity: root.lateWide
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
            opacity: root.lateWide
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
        height: root.revealH
        clip: true
    }
}
