import QtQuick
import Quickshell
import Quickshell.Io
import "../Config"
import "../Island"
import "../Ui"

// ═══════════════════════════════════════════
//  CLIPBOARD — histórico do cliphist.
//
//  Item idle: [ícone do tipo] conteúdo numa linha (elide).
//  Item selecionado (hover OU setas, estilo caelestia) expande:
//    title bar:  data/hora | ícone do tipo (viaja da esquerda
//                ao centro) | copiar · excluir
//    body:       texto (scroll interno) / imagem / path do vídeo
//    foot:       tamanho + caracteres (txt) / dimensões (img) /
//                duração (vídeo)
//
//  Teclas: ↑↓ move · Enter/Space/Ctrl+C copia · Backspace remove
//  do histórico · Delete remove E apaga o arquivo (só vídeos/paths)
//  · Esc fecha. Limpar tudo: vassoura no topo-direita.
//
//  Persistência: o próprio cliphist guarda o histórico em disco
//  (~/.cache/cliphist/db). Timestamps são NOSSOS (sidecar JSON —
//  o cliphist não registra hora). Dedup: o cliphist já joga
//  conteúdo repetido pro topo ao re-armazenar.
//
//  Requer o coletor: wl-paste --type text/image --watch cliphist store
//  IPC: qs -c vtnc ipc call clipboard toggle
// ═══════════════════════════════════════════
IslandFace {
    id: root

    name: "clipboard"
    role: "app"
    grabsKeyboard: true

    contentWidth: 560
    contentHeight: Theme.contentPadding * 2 + 32 + 420

    // {id, preview, kind: "text"|"image"|"video", ext, imgSize, imgDims}
    property var items: []
    property int selIndex: 0
    // Caches por id (conteúdo completo, imagem pronta, meta de vídeo)
    property var fullText: ({})
    property var imgReady: ({})
    property var videoMeta: ({})
    property int cacheRev: 0

    function reload() {
        listProc.running = true
    }

    onActiveChanged: {
        if (active) {
            selIndex = 0
            reload()
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: kb.forceActiveFocus()
    }

    // ─── TIMESTAMPS (sidecar nosso; cliphist não guarda hora) ───
    FileView {
        id: stampsFile

        path: "/home/thpc/.cache/vtnc-clipstamps.json"
        // síncrono: o 1º `cliphist list` não pode chegar antes dos
        // carimbos, senão re-carimba tudo como "agora"
        blockLoading: true

        adapter: JsonAdapter {
            id: stampsData
            property var stamps: ({})
        }
    }

    function fmtStamp(id) {
        const t = stampsData.stamps[id]
        return t ? Qt.formatDateTime(new Date(t), "d MMM · HH:mm") : "—"
    }

    function fmtBytes(n) {
        if (n >= 1048576) return `${(n / 1048576).toFixed(1)} MiB`
        if (n >= 1024) return `${(n / 1024).toFixed(0)} KiB`
        return `${n} B`
    }

    // ─── LISTA (cliphist list → "id\tpreview") ───
    Process {
        id: listProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const arr = []
                const seen = ({})
                const now = Date.now()
                const st = stampsData.stamps ?? ({})
                let stDirty = false

                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 0)
                        continue
                    const id = line.slice(0, tab)
                    const preview = line.slice(tab + 1)

                    const img = preview.match(
                        /^\[\[ binary data ([\d.]+ \w+) (\w+) (\d+)x(\d+) \]\]$/)
                    const vid = preview.trim().match(
                        /^(?:file:\/\/)?(\/\S*\.(mp4|mkv|webm|mov|avi))$/i)

                    arr.push({
                        id: id,
                        preview: preview,
                        kind: img ? "image" : (vid ? "video" : "text"),
                        ext: img ? (img[2] === "jpg" ? "jpeg" : img[2]) : "",
                        imgSize: img ? `${img[1]} ${img[2]}` : "",
                        imgDims: img ? `${img[3]}×${img[4]}` : "",
                        path: vid ? vid[1] : ""
                    })

                    seen[id] = true
                    if (st[id] === undefined) {
                        st[id] = now
                        stDirty = true
                    }
                }
                // poda carimbos de entradas que já morreram
                for (const k in st) {
                    if (!seen[k]) {
                        delete st[k]
                        stDirty = true
                    }
                }
                if (stDirty) {
                    stampsData.stamps = st
                    stampsFile.writeAdapter()
                }

                root.items = arr
                if (root.selIndex >= arr.length)
                    root.selIndex = Math.max(0, arr.length - 1)
                root.cacheRev++
            }
        }
    }

    // ─── DECODES DO SELECIONADO ───
    Process {
        id: textDecode

        property string forId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                root.fullText[textDecode.forId] = text
                root.cacheRev++
            }
        }
    }

    Process {
        id: imgDecode

        property string forId: ""

        onExited: {
            root.imgReady[forId] = true
            root.cacheRev++
        }
    }

    Process {
        id: metaProc

        property string forId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                root.videoMeta[metaProc.forId] = (l[0] === "MISSING")
                    ? { missing: true }
                    : { size: parseInt(l[0]) || 0, dur: parseFloat(l[1]) || 0 }
                root.cacheRev++
            }
        }
    }

    onSelIndexChanged: decodeSelected()
    onItemsChanged: decodeSelected()

    function decodeSelected() {
        const it = items[selIndex]
        if (!it)
            return
        if (it.kind === "image") {
            if (imgReady[it.id])
                return
            imgDecode.forId = it.id
            imgDecode.command = ["sh", "-c",
                `[ -f '/tmp/vtnc-clip-${it.id}' ] || cliphist decode ${it.id} > '/tmp/vtnc-clip-${it.id}'`]
            imgDecode.running = true
        } else if (it.kind === "video") {
            if (videoMeta[it.id])
                return
            metaProc.forId = it.id
            metaProc.command = ["sh", "-c",
                `f='${it.path}'; if [ -f "$f" ]; then stat -c %s "$f";`
                + ` ffprobe -v error -show_entries format=duration -of csv=p=0 "$f";`
                + ` else echo MISSING; fi`]
            metaProc.running = true
        } else if (fullText[it.id] === undefined) {
            textDecode.forId = it.id
            textDecode.command = ["cliphist", "decode", it.id]
            textDecode.running = true
        }
    }

    // ─── AÇÕES ───
    function copyItem(it) {
        if (!it)
            return
        const t = it.kind === "image" ? `wl-copy -t image/${it.ext}` : "wl-copy"
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${it.id} | ${t}`])
        closeRequested() // copiar SEMPRE fecha; excluir nunca
    }

    // wipeFile: além do histórico, apaga o arquivo (só faz sentido
    // para paths de vídeo — texto/imagem não têm arquivo próprio)
    function deleteItem(it, wipeFile) {
        if (!it)
            return
        Quickshell.execDetached(["sh", "-c",
            `cliphist list | grep -P '^${it.id}\\t' | cliphist delete`])
        if (wipeFile && it.kind === "video" && it.path !== "")
            Quickshell.execDetached(["rm", "-f", it.path])
        reloadTimer.restart()
    }

    function wipeAll() {
        Quickshell.execDetached(["cliphist", "wipe"])
        reloadTimer.restart()
    }

    Timer {
        id: reloadTimer
        interval: 150
        onTriggered: root.reload()
    }

    function moveSel(dir) {
        if (items.length === 0)
            return
        selIndex = Math.max(0, Math.min(items.length - 1, selIndex + dir))
        list.positionViewAtIndex(selIndex, ListView.Contain)
    }

    // ─── TECLADO ───
    Item {
        id: kb

        anchors.fill: parent
        focus: root.active

        Keys.onPressed: event => {
            const it = root.items[root.selIndex]
            switch (event.key) {
            case Qt.Key_Down: root.moveSel(1); break
            case Qt.Key_Up: root.moveSel(-1); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                root.copyItem(it)
                break
            case Qt.Key_C:
                if (!(event.modifiers & Qt.ControlModifier))
                    return
                root.copyItem(it)
                break
            case Qt.Key_Backspace:
                root.deleteItem(it, false)
                break
            case Qt.Key_Delete:
                root.deleteItem(it, true)
                break
            case Qt.Key_Escape: root.closeRequested(); break
            default: return
            }
            event.accepted = true
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.contentPadding
        spacing: 8

        // ─── CABEÇALHO (com Limpar no topo-direita) ───
        Item {
            width: parent.width
            height: 24

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: "󰅍"
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: Theme.fontIcon; pixelSize: 15 }
                }

                Text {
                    text: "Clipboard"
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: Theme.fontDisplay; pixelSize: 14; weight: 650 }
                }

                Text {
                    text: `${root.items.length}`
                    color: Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: Theme.fontMono; pixelSize: 11 }
                }
            }

            // Limpar TUDO (botão de texto padrão)
            Hoverable {
                id: wipeChip

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: wipeText.implicitWidth + 14
                height: 20
                onTapped: root.wipeAll()

                Text {
                    id: wipeText

                    anchors.centerIn: parent
                    text: "Limpar"
                    color: wipeChip.hovered ? Theme.textPrimary : Theme.textMuted
                    font { family: Theme.fontDisplay; pixelSize: 11 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }
            }
        }

        // ─── PILHA DE ITENS ───
        ListView {
            id: list

            width: parent.width
            height: 420
            model: root.items
            clip: true
            spacing: 6

            Column {
                anchors.centerIn: parent
                visible: root.items.length === 0
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Histórico vazio"
                    color: Theme.textMuted
                    font { family: Theme.fontDisplay; pixelSize: 12 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "requer: wl-paste --watch cliphist store"
                    color: Theme.textMuted
                    font { family: Theme.fontMono; pixelSize: 10 }
                }
            }

            delegate: Rectangle {
                id: box

                required property var modelData
                required property int index

                readonly property bool sel: root.selIndex === index
                readonly property string kind: modelData.kind
                readonly property string typeIconGlyph:
                    kind === "image" ? "󰋩" : (kind === "video" ? "󰕧" : "󰈙")

                readonly property string full: {
                    root.cacheRev
                    return root.fullText[modelData.id] ?? ""
                }
                readonly property bool imgOk: {
                    root.cacheRev
                    return root.imgReady[modelData.id] === true
                }
                readonly property var vmeta: {
                    root.cacheRev
                    return root.videoMeta[modelData.id]
                }

                // ── FOOT por tipo ──
                readonly property string footText: {
                    if (kind === "image")
                        return `${modelData.imgSize} · ${modelData.imgDims}`
                    if (kind === "video") {
                        if (!vmeta) return "…"
                        if (vmeta.missing) return "arquivo não encontrado"
                        const m = Math.floor(vmeta.dur / 60)
                        const s = Math.round(vmeta.dur % 60)
                        return `${root.fmtBytes(vmeta.size)} · ${m}:${String(s).padStart(2, "0")}`
                    }
                    if (full === "") return "…"
                    const bytes = unescape(encodeURIComponent(full)).length
                    return `${root.fmtBytes(bytes)} · ${full.length} caracteres`
                }

                // ── ALTURAS ──
                readonly property real bodyH: {
                    if (kind === "image") return 118
                    if (kind === "video") return videoPath.implicitHeight + 8
                    return Math.min(104, fullTextItem.implicitHeight + 6)
                }
                readonly property real expandedH: 30 + bodyH + 22

                width: list.width
                height: sel ? expandedH : 34
                Behavior on height {
                    NumberAnimation { duration: 240; easing.type: Easing.OutQuart }
                }

                radius: 12
                // Fundo bg (preto) nos DOIS estados; seleção fala
                // pelo accent do ícone e pela própria expansão
                color: Theme.bg
                clip: true

                // ── ÍCONE DO TIPO: fixo à esquerda nos dois estados ──
                Text {
                    id: typeIcon

                    x: 10
                    y: box.sel ? 9 : (34 - height) / 2
                    Behavior on y {
                        NumberAnimation { duration: 240; easing.type: Easing.OutQuart }
                    }
                    text: box.typeIconGlyph
                    color: box.sel ? Theme.accent : Theme.textMuted
                    font { family: Theme.fontIcon; pixelSize: 13 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                // ── IDLE: conteúdo numa linha ──
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    y: (34 - implicitHeight) / 2
                    text: box.kind === "image"
                        ? box.modelData.preview.replace(/^\[\[ binary data (.*) \]\]$/, "$1")
                        : box.modelData.preview.trim()
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    opacity: box.sel ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Motion.quick } }
                    font { family: Theme.fontDisplay; pixelSize: 11 }
                }

                // ── EXPANDIDO ──
                Item {
                    anchors.fill: parent
                    anchors.margins: 8
                    opacity: box.sel ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Motion.quick } }

                    // TITLE BAR: ícone (esq, fixo) | data/hora (centro) | ações
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        text: root.fmtStamp(box.modelData.id)
                        color: Theme.textMuted
                        font { family: Theme.fontMono; pixelSize: 10 }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 2

                        // O Hoverable usa ReleaseWithinBounds, que toma
                        // grab: sem isso o tap do CORPO também dispararia
                        Hoverable {
                            id: copyChip

                            width: 22
                            height: 20
                            onTapped: root.copyItem(box.modelData)

                            Text {
                                anchors.centerIn: parent
                                text: "󰆏"
                                color: copyChip.hovered ? Theme.accent : Theme.textMuted
                                font { family: Theme.fontIcon; pixelSize: 12 }
                                Behavior on color { ColorAnimation { duration: Motion.instant } }
                            }
                        }

                        // Grab do Hoverable: excluir NÃO pode acionar o
                        // copiar-e-fechar do corpo por baixo
                        Hoverable {
                            id: delChip

                            width: 22
                            height: 20
                            onTapped: root.deleteItem(box.modelData, false)

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: delChip.hovered ? Theme.danger : Theme.textMuted
                                font { family: Theme.fontIcon; pixelSize: 12 }
                                Behavior on color { ColorAnimation { duration: Motion.instant } }
                            }
                        }
                    }

                    // BODY: texto (scroll interno)
                    Flickable {
                        anchors.fill: parent
                        anchors.topMargin: 24
                        anchors.bottomMargin: 16
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        contentHeight: fullTextItem.implicitHeight
                        clip: true
                        interactive: box.sel
                        visible: box.kind === "text"

                        Text {
                            id: fullTextItem

                            width: box.width - 24
                            text: box.full !== "" ? box.full : box.modelData.preview
                            color: Theme.textPrimary
                            wrapMode: Text.Wrap
                            font { family: Theme.fontMono; pixelSize: 11 }
                        }
                    }

                    // BODY: imagem
                    Image {
                        anchors.top: parent.top
                        anchors.topMargin: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 112
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        visible: box.kind === "image" && box.imgOk
                        source: visible ? `file:///tmp/vtnc-clip-${box.modelData.id}` : ""
                    }

                    // BODY: vídeo = path
                    Text {
                        id: videoPath

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 26
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        visible: box.kind === "video"
                        text: box.modelData.path
                        color: Theme.textPrimary
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 2
                        elide: Text.ElideMiddle
                        font { family: Theme.fontMono; pixelSize: 11 }
                    }

                    // FOOT: centro
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: box.footText
                        color: Theme.textMuted
                        font { family: Theme.fontMono; pixelSize: 9 }
                    }
                }

                // Hover = seleção; clique no corpo copia (e fecha)
                HoverHandler {
                    onHoveredChanged: {
                        if (hovered)
                            root.selIndex = box.index
                    }
                }
                TapHandler { onTapped: root.copyItem(box.modelData) }
            }
        }
    }
}
