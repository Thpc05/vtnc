import QtQuick
import "../DashWidgets/Horizontais"
import "../Services"

// ═══════════════════════════════════════════
//  DASHBOARD — Quebra-cabeça de widgets em posições FIXAS.
//
//  LAYOUT: grid explícito por coordenada, unidade = 1 SUBCOLUNA
//  (metade de um quarter; 8 por linha). Cada widget tem sua própria
//  posição (gridCol, gridRow) — não existe fluxo nem auto-encaixe:
//  um slot pode ficar vazio de propósito. NINGUÉM se move quando um
//  vizinho expande — o container (dashboard → pill) é que CRESCE pra
//  acomodar, pros lados e/ou pra baixo.
//
//  FLUIDEZ: width/height do container e x/y de cada widget são todos
//  Behaviors com a mesma duração/easing — crescem juntos. NUNCA usar
//  Flow + move Transition: com tamanhos animando, os dois se atropelam
//  e os widgets sobrepõem.
//
//  Drag: soltar sobre outro widget TROCA as duas posições. Soltar em
//  espaço vazio só move.
//  Pin: botão direito trava o widget expandido.
//
//  Registrar um widget = criar em DashWidgets/Horizontais/ +
//  declarar aqui com gridCol/gridRow.
// ═══════════════════════════════════════════
Item {
    id: root

    // Largura BASE (piso mínimo, setada pela Bar) — widget expandindo
    // além dela faz o container crescer (layoutWidth)
    property real baseWidth: 400
    // Unidade do grid: SUBCOLUNA (metade de um quarter)
    readonly property int subCols: Theme.dashColumns * 2
    readonly property real cellW:
        (baseWidth - (subCols - 1) * Theme.dashGap) / subCols

    property real layoutWidth: baseWidth
    Behavior on layoutWidth {
        Settle {}
    }
    width: layoutWidth

    readonly property list<Item> widgets: [wMedia, wNet, wBt, wCal, wAudio]

    // Algum widget quer o teclado? (campo de senha etc.)
    readonly property bool wantsKeyboard: {
        for (let i = 0; i < widgets.length; i++)
            if (widgets[i].wantsKeyboard)
                return true
        return false
    }

    // ═══════════════════════════════════════════
    //  HOVER → EXPANDIR (um por vez + grace; drag não expande)
    // ═══════════════════════════════════════════
    readonly property Item hoveredWidget: {
        for (let i = 0; i < widgets.length; i++)
            if (widgets[i].hovered && !widgets[i].dragging)
                return widgets[i]
        return null
    }

    HoverGroup {
        id: widgetGroup
        candidate: root.hoveredWidget
    }
    readonly property Item shownWidget: widgetGroup.shown

    // Dashboard fechou → recolhe o hover (pins ficam)
    onVisibleChanged: if (!visible) widgetGroup.closeNow()

    function isExpanded(w) {
        return w.pinned || shownWidget === w
    }

    // ═══════════════════════════════════════════
    //  LAYOUT: posições FIXAS — só converte (gridCol, gridRow) em
    //  pixel e mede o quanto o container precisa crescer pra caber
    //  todo mundo no tamanho ATUAL (idle ou expandido)
    // ═══════════════════════════════════════════
    property real layoutHeight: 0
    Behavior on layoutHeight {
        Settle {}
    }
    implicitHeight: layoutHeight

    // ═══════════════════════════════════════════
    //  EMPURRÃO EM SOMBRA
    //  O expandido NUNCA se move: cresce da própria posição. Quem cai
    //  na sombra do crescimento FOGE na direção dele: à direita →
    //  desliza pra direita; embaixo → desce; diagonal → os dois.
    //  Empurrado vira empurrador (cascata). A dashboard/pill crescem
    //  pra acomodar o bounding box final.
    //
    //  A direção da fuga vem da geometria IDLE (que nunca tem
    //  sobreposição): determinístico — mesmo hover, mesmo resultado.
    //
    //  Fuga é TRANSIENTE: só o x/y renderizado muda, nunca o
    //  gridCol/gridRow — recolheu, todo mundo volta sozinho.
    // ═══════════════════════════════════════════
    function rectsOverlap(a, b) {
        return a.col < b.col + b.span && a.col + a.span > b.col
            && a.row < b.row + b.rows && a.row + a.rows > b.row
    }

    // Sobreposição entre as ÂNCORAS idle de dois widgets (gridCol/Row
    // + spanIdle/rows). O empurrão-em-sombra CONFIA que isto é sempre
    // falso pra todo par — resolveIdle() garante essa invariante.
    function idleOverlap(a, b) {
        return a.gridCol < b.gridCol + b.spanIdle && a.gridCol + a.spanIdle > b.gridCol
            && a.gridRow < b.gridRow + b.rows && a.gridRow + a.rows > b.gridRow
    }

    // ── BLINDAGEM DO IDLE ──
    // Depois de qualquer drop/restauração as âncoras podem colidir
    // (spans diferentes num swap, posição persistida velha, etc). Aqui
    // reacomodamos até NENHUM par se sobrepor: `anchor` (o widget
    // recém-solto) mantém sua célula e tem prioridade; os colididos
    // cedem descendo pra logo abaixo do que os empurra. Só desce
    // (monotônico) → converge sempre; o container cresce em altura.
    function resolveIdle(anchor) {
        const order = [...widgets].sort((a, b) => {
            if (a === anchor) return -1
            if (b === anchor) return 1
            return (a.gridRow - b.gridRow) || (a.gridCol - b.gridCol)
        })
        let guard = widgets.length * widgets.length * 4
        let moved = true
        while (moved && guard-- > 0) {
            moved = false
            for (let i = 0; i < order.length; i++) {
                for (let j = i + 1; j < order.length; j++) {
                    const a = order[i]
                    const b = order[j]
                    if (!idleOverlap(a, b))
                        continue
                    b.gridRow = a.gridRow + a.rows // b cede, desce
                    moved = true
                }
            }
        }
    }

    // `skip`: widget sendo arrastado (posição fica com o mouse)
    function relayout(skip) {
        const stepX = cellW + Theme.dashGap
        const stepY = Theme.dashCell + Theme.dashGap

        // 1) rects de trabalho: idle pra todos; expandidos já com o
        //    tamanho expandido. O canto esquerdo recua `leftGrow`
        //    subcolunas (expansão pra esquerda/ambos) — col pode ficar
        //    NEGATIVO aqui; a normalização no passo 3 resolve.
        const rect = new Map()
        for (const w of widgets) {
            const exp = isExpanded(w)
            rect.set(w, {
                col: exp ? w.gridCol - w.leftGrow : w.gridCol,
                row: w.gridRow,
                span: exp ? w.spanExp : w.spanIdle,
                rows: exp ? w.rowsExp : w.rows
            })
        }

        // Sombra pela geometria idle (não muda com empurrões)
        const leftOf = (w, p) => w.gridCol + w.spanIdle <= p.gridCol
        const rightOf = (w, p) => w.gridCol >= p.gridCol + p.spanIdle
        const below = (w, p) => w.gridRow >= p.gridRow + p.rows

        // 2) Empurrões por PRIORIDADE (ordem de leitura das âncoras):
        //    cada widget só empurra quem vem DEPOIS dele. Assim um
        //    EXPANDIDO empurra outro expandido também (dois fixos, ou
        //    fixo + hover, nunca se sobrepõem) — o de âncora posterior
        //    cede. A fuga segue o lado do vizinho na geometria idle:
        //    à esquerda foge pra ESQUERDA (col negativa ok), à direita
        //    pra direita, embaixo desce. O guard limita qualquer caso
        //    patológico de cabo-de-guerra entre dois empurradores.
        const byGrid = (a, b) => (a.gridRow - b.gridRow) || (a.gridCol - b.gridCol)
        const order = [...widgets].sort(byGrid)
        let guard = widgets.length * widgets.length * 4
        let changed = true
        while (changed && guard-- > 0) {
            changed = false
            for (let i = 0; i < order.length; i++) {
                const p = order[i]
                const pr = rect.get(p)
                for (let j = i + 1; j < order.length; j++) {
                    const w = order[j]
                    const wr = rect.get(w)
                    if (!rectsOverlap(pr, wr))
                        continue
                    if (leftOf(w, p))
                        wr.col = pr.col - wr.span // desliza pra esquerda
                    else if (rightOf(w, p))
                        wr.col = pr.col + pr.span // desliza pra direita
                    else if (below(w, p))
                        wr.row = pr.row + pr.rows // desce
                    else { // diagonal (direita-baixo)
                        wr.col = pr.col + pr.span
                        wr.row = pr.row + pr.rows
                    }
                    changed = true
                }
            }
        }

        // 3) normaliza (colunas negativas → desloca tudo pra dentro) e
        //    aplica; o bounding box dita o tamanho do container. A
        //    dashboard é centrada na pill, então "crescer pra esquerda"
        //    é só a largura crescer com o resto deslocado.
        let minCol = 0
        let maxCol = subCols
        let maxRow = 1
        for (const w of widgets) {
            const r = rect.get(w)
            minCol = Math.min(minCol, r.col)
            maxCol = Math.max(maxCol, r.col + r.span)
            maxRow = Math.max(maxRow, r.row + r.rows)
        }
        for (const w of widgets) {
            const r = rect.get(w)
            if (w !== skip) {
                w.x = (r.col - minCol) * stepX
                w.y = r.row * stepY
            }
        }
        layoutWidth = Math.max(baseWidth, (maxCol - minCol) * stepX - Theme.dashGap)
        layoutHeight = maxRow * stepY - Theme.dashGap
    }

    onShownWidgetChanged: relayout(dragWidget)
    onCellWChanged: relayout(dragWidget)

    // ═══════════════════════════════════════════
    //  DRAG — solta a peça no grid. Cai SOBRE outro widget (qualquer
    //  parte da área dele, não só o canto) → TROCA as âncoras. Cai em
    //  espaço vazio → só move. Em ambos os casos resolveIdle() blinda
    //  o resultado: o idle nunca fica com sobreposição.
    // ═══════════════════════════════════════════
    property Item dragWidget: null

    function handleDrop(w) {
        const stepX = cellW + Theme.dashGap
        const stepY = Theme.dashCell + Theme.dashGap

        // Célula-âncora alvo pelo canto renderizado, presa ao grid
        // (não deixa o span transbordar a borda direita)
        let col = Math.round(w.x / stepX)
        let row = Math.max(0, Math.round(w.y / stepY))
        col = Math.max(0, Math.min(col, subCols - w.spanIdle))

        // Widget cuja ÁREA idle cobre a célula alvo (swap por cobertura)
        const other = widgets.find(o => o !== w
            && col >= o.gridCol && col < o.gridCol + o.spanIdle
            && row >= o.gridRow && row < o.gridRow + o.rows)

        if (other) {
            // Troca de âncoras (limpo quando os spans batem; o que
            // sobrar de colisão por spans diferentes, resolveIdle corrige)
            const oc = other.gridCol
            const orow = other.gridRow
            other.gridCol = w.gridCol
            other.gridRow = w.gridRow
            w.gridCol = oc
            w.gridRow = orow
        } else {
            w.gridCol = col
            w.gridRow = row
        }

        resolveIdle(w)
        savePositions()
        relayout(null)
    }

    function savePositions() {
        const pos = {}
        for (const w of widgets)
            pos[w.name] = { col: w.gridCol, row: w.gridRow }
        Persist.state.widgetLayout = pos
    }

    // ── RESTAURAÇÃO DO PERSISTIDO ──
    // ARMADILHA: o singleton Persist é LAZY e o load aplica DEPOIS do
    // primeiro acesso — restaurar no onCompleted pega só os defaults.
    // Aplica quando Persist.loaded vira true (ou na hora, se já veio).
    function applyPersisted() {
        const saved = Persist.state.widgetLayout ?? ({})
        for (const w of widgets) {
            const p = saved[w.name]
            if (p) {
                // Prende ao grid: um persistido velho/inválido (span
                // transbordando, coluna fora) não pode furar a invariante
                w.gridCol = Math.max(0, Math.min(p.col, subCols - w.spanIdle))
                w.gridRow = Math.max(0, p.row)
            }
            w.pinned = Persist.state.widgetPins[w.name] === true
        }
        resolveIdle(null) // blinda contra qualquer colisão herdada
        relayout(null)
    }

    Connections {
        target: Persist
        function onLoadedChanged() {
            if (Persist.loaded)
                root.applyPersisted()
        }
    }

    // Wiring pelo contrato
    Component.onCompleted: {
        for (let i = 0; i < widgets.length; i++) {
            const w = widgets[i]
            w.cellW = Qt.binding(() => root.cellW)
            w.expanded = Qt.binding(() => w.pinned || root.shownWidget === w)
            // Clique no widget pula a espera do hover
            w.tapped.connect(() => widgetGroup.openNow(w))
            w.pinnedChanged.connect(() => {
                const pins = Persist.state.widgetPins
                pins[w.name] = w.pinned
                Persist.state.widgetPins = pins // reatribui → salva sozinho
                root.relayout(root.dragWidget)
            })
            w.draggingChanged.connect(() => {
                if (w.dragging) {
                    root.dragWidget = w
                } else {
                    root.dragWidget = null
                    root.handleDrop(w)
                }
            })
        }

        if (Persist.loaded)
            applyPersisted()
        else
            relayout(null)
    }

    // ═══════════════════════════════════
    //  WIDGETS — posição inicial em SUBCOLUNAS (gridCol, gridRow):
    //  [média(0,0) big | rede(4,0) normal | bt(6,0) normal]
    //  [calendário(0,1) big | volume(4,1) big]
    //  sizeIdle/sizeExpand/expandDir são editáveis por instância
    //  (defaults declarados em cada widget).
    //  (notificações moram no NotifReveal, que funciona na dashboard)
    // ═══════════════════════════════════
    MediaWidgetHorizontais     { id: wMedia; gridCol: 0; gridRow: 0 }
    NetworkWidgetHorizontais   { id: wNet;   gridCol: 4; gridRow: 0 }
    BluetoothWidgetHorizontais { id: wBt;    gridCol: 6; gridRow: 0 }
    CalendarWidgetHorizontais  { id: wCal;   gridCol: 0; gridRow: 1 }
    VolumeWidgetHorizontais    { id: wAudio; gridCol: 4; gridRow: 1 }
}
