import QtQuick

// ═══════════════════════════════════════════
//  DASH WIDGET — Contrato de um widget da dashboard.
//  Uma peça do quebra-cabeça: posição FIXA e explícita no grid
//  (gridCol, gridRow, em SUBCOLUNAS = metade de um quarter).
//  Ninguém se move quando um vizinho expande — a Dashboard (o
//  container) é que cresce pra acomodar.
//
//  Contrato:
//   - `gridCol`/`gridRow` definem a posição (setados pela Dashboard:
//     default declarado na instância, ou restaurados do persistido;
//     arrastar-e-soltar troca com quem estiver lá)
//   - `expanded` é setado pela Dashboard (hover com grace, ou pin)
//   - botão direito fixa (pin) — fica expandido até despinar
//   - segurar e arrastar move a peça; soltar troca de lugar
//   - conteúdo é filho normal (host com margens); o extra do estado
//     expandido deriva de `lateReveal` (0 → 1)
//   - `background` recebe conteúdo full-bleed atrás de tudo
// ═══════════════════════════════════════════
Rectangle {
    id: widget

    property string name: ""
    // Posição no grid (unidade = 1 SUBCOLUNA). Setada pela Dashboard.
    property int gridCol: 0
    property int gridRow: 0

    // ── CONFIGURAÇÃO (editável por instância) ──
    //  Unidade do grid = SUBCOLUNA (metade de um quarter).
    //  Tamanhos (largura; a altura de linha é uniforme):
    //   "small"  = 1 subcol (meio quarter)
    //   "normal" = 2 (um quarter)
    //   "big"    = 4 (metade da dashboard)
    //   "full"   = 8 (a dashboard inteira)
    //  Nem todo widget suporta todos — o header de cada arquivo
    //  documenta os permitidos.
    property string sizeIdle: "normal"
    property string sizeExpand: "big"

    //  DIREÇÃO da expansão (pra onde a largura extra vai e se ganha
    //  linhas):
    //   "down"       → só desce (largura extra vai pra direita)
    //   "left"/"right"           → só largura, altura fixa
    //   "down-left"/"down-right" → desce + largura pro lado
    //   "down-both"  → desce + largura pros DOIS lados (centrado)
    property string expandDir: "down"

    function spanOf(s) {
        return s === "full" ? 8 : (s === "big" ? 4 : (s === "small" ? 1 : 2))
    }
    readonly property int spanIdle: spanOf(sizeIdle)
    readonly property int spanExp: Math.max(spanOf(sizeExpand), spanIdle)
    // Todo widget ocupa 1 linha no idle; "down*" adiciona linhas ao
    // expandir
    readonly property int rows: 1
    readonly property int rowsExp: expandDir.indexOf("down") >= 0 ? 3 : 1

    //  Quantas subcolunas o canto ESQUERDO recua ao expandir
    //  (a Dashboard ancora o rect expandido em gridCol − leftGrow)
    readonly property int leftGrow: {
        const extra = spanExp - spanIdle
        if (expandDir === "left" || expandDir === "down-left")
            return extra
        if (expandDir === "down-both")
            return Math.floor(extra / 2)
        return 0
    }

    // ── Setados pela Dashboard ──
    property real cellW: 120
    property bool expanded: false

    // Pin: botão direito trava o expandido
    property bool pinned: false

    // Widget pede o teclado (ex: campo de senha do wifi) — a cadeia
    // Dashboard → Bar → Pill → shell entrega
    property bool wantsKeyboard: false

    readonly property bool hovered: hoverH.hovered
    readonly property bool dragging: dragH.active

    // ── DRIVER da expansão in-place ──
    property real reveal: expanded ? 1 : 0
    Behavior on reveal {
        Settle {}
    }
    // Conteúdo expandido aparece na 2ª metade (e some na 1ª do colapso)
    readonly property real lateReveal: Math.max(0, reveal * 2 - 1)

    function cellSpan(n, unit) { return n * unit + (n - 1) * Theme.dashGap }

    readonly property real idleH: cellSpan(rows, Theme.dashCell)
    readonly property real fullH: cellSpan(rowsExp, Theme.dashCell)
    readonly property real idleW: cellSpan(spanIdle, cellW)
    readonly property real fullW: cellSpan(spanExp, cellW)

    // ── HEADER (padronizado): a faixa de conteúdo da altura idle.
    //  Todo widget mostra ali só ÍCONE + DADO (sem nome), ambos
    //  centralizados verticalmente nela. Expandido, o header
    //  permanece nessa mesma faixa do topo
    readonly property real headerH: idleH - 24 // 24 = margens do contentHost

    width: idleW + (fullW - idleW) * reveal
    height: idleH + (fullH - idleH) * reveal

    // Posição vem do relayout da Dashboard; anima em paralelo com a
    // altura (mesma duração/easing). Durante o drag, o dedo manda
    Behavior on x {
        enabled: !widget.dragging
        Smooth {}
    }
    Behavior on y {
        enabled: !widget.dragging
        Smooth {}
    }
    z: dragging ? 10 : 0

    radius: Theme.radiusCard
    color: Theme.widgetBgColor
    // Borda acende SÓ com o mouse em cima (pinado não conta)
    border.width: 1
    border.color: hovered ? Theme.widgetBorderHoverColor : Theme.widgetBorderColor
    Behavior on border.color { ColorAnimation { duration: Motion.instant } }
    clip: true

    // Clique simples: pula a espera do hover (a Dashboard escuta)
    signal tapped()

    HoverHandler { id: hoverH }

    // Botão direito: pin/unpin
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: widget.pinned = !widget.pinned
    }

    // Segurar e mover — a Dashboard escuta `dragging` e x/y
    DragHandler {
        id: dragH
        acceptedButtons: Qt.LeftButton
    }

    // Clique esquerdo sem arrastar. Convive com o DragHandler acima:
    // passado o limiar de movimento o drag toma o grab e este desiste,
    // então arrastar não conta como clique
    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: widget.tapped()
    }

    // Fundo full-bleed (atrás do conteúdo, sem margens)
    property alias background: bgHost.data

    Item {
        id: bgHost
        anchors.fill: parent
    }

    // Filhos declarados no widget concreto caem aqui
    default property alias content: contentHost.data

    Item {
        id: contentHost
        anchors.fill: parent
        anchors.margins: Theme.cardPadding
    }

    // ── CADEADO: fixa o widget. SÓ aparece com o mouse em cima
    //  (pinado sem hover fica invisível — o estado mora no accent) ──
    Item {
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 20
        height: 18
        z: 5
        opacity: widget.hovered ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.instant } }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusChip
            color: lockHover.hovered ? Theme.hoverLayer : "transparent"
            Behavior on color { ColorAnimation { duration: Motion.instant } }
        }

        Text {
            anchors.centerIn: parent
            text: "󰌾"
            color: widget.pinned ? Theme.accent : Theme.textMuted
            font { family: Theme.fontIcon; pixelSize: 11 }
            Behavior on color { ColorAnimation { duration: Motion.instant } }
        }

        HoverHandler { id: lockHover }
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: widget.pinned = !widget.pinned
        }
    }
}
