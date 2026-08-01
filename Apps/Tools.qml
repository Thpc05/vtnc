import QtQuick
import Quickshell
import Quickshell.Io
import "../Components"
import "../Components/Pill"

// ═══════════════════════════════════════════
//  TOOLS — paleta de ferramentas rápidas.
//  Ícones brancos; gravação ativa fica accent + indicador pulsante.
//  Grupos separados por linhas sutis: Screenshot | Rec | Extras.
//
//  Navegação: hover e SELEÇÃO são o mesmo índice — mouse mira,
//  ←/→ movem (pulando separadores), Enter dispara, Esc fecha.
//
//  REGRA DE OURO: qualquer ferramenta que usa slurp/captura FECHA
//  a paleta antes de rodar — a camada fullscreen dela (teclado
//  exclusivo) bloqueia o overlay do slurp, que fica preso invisível.
//  A gravação continua com a paleta fechada; reabrir mostra o
//  indicador e permite parar.
//
//  IPC: qs -c vtnc ipc call tools toggle
// ═══════════════════════════════════════════
PillFace {
    id: root

    name: "tools"
    role: "app"
    grabsKeyboard: true

    // Gravação em andamento ("" = nenhuma) — PERSISTE ao fechar/abrir
    property string recTool: ""
    readonly property bool recording: recTool !== ""
    // Selecionada (hover do mouse OU setas)
    property int selIndex: 0

    // Enquanto o slurp escolhe a região, a paleta solta o grab
    // (teclado + mask) SEM fechar — senão o overlay dele fica preso
    releaseInput: slurpProc.running

    contentWidth: toolsRow.implicitWidth + Theme.contentPadding * 2
    contentHeight: Config.showTips ? 64 : 48

    onActiveChanged: {
        if (active) {
            selIndex = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: kb.forceActiveFocus()
    }

    // ── FERRAMENTAS (id, glyph, legenda; rec = gravação) ──
    readonly property var toolModel: [
        { id: "shotCrop",    icon: "󰆞", label: "Print · recorte" },
        { id: "shotFull",    icon: "󰹑", label: "Print · tela cheia" },
        { sep: true },
        { id: "recCrop",     icon: "󰕧", label: "Gravar · recorte", rec: true },
        { id: "recFull",     icon: "󰑊", label: "Gravar · tela cheia", rec: true },
        { id: "recFullMic",  icon: "󰍬", label: "Gravar · tela + mic", rec: true },
        { indicator: true,   label: "Gravando — clique para parar" },
        { sep: true },
        { id: "colorPicker", icon: "󰈊", label: "Conta-gotas" },
        { id: "ocr",         icon: "󰊄", label: "OCR → clipboard" }
    ]

    // Move a seleção pulando separadores e o indicador escondido
    function move(dir) {
        let i = selIndex
        do {
            i = (i + dir + toolModel.length) % toolModel.length
        } while (toolModel[i].sep || (toolModel[i].indicator && !recording))
        selIndex = i
    }

    // ── SLURP (etapa 1 do recCrop) ──
    // Processo próprio: a região sai no stdout; cancelou (Esc),
    // sai vazio e o rec desarma
    property string pendingFile: ""

    Process {
        id: slurpProc

        // </dev/null é VITAL: com stdin em pipe (padrão do Process),
        // o slurp fica lendo stdin à espera de EOF e nunca mapeia
        command: ["sh", "-c", "exec slurp < /dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const region = text.trim()
                if (root.recTool !== "recCrop")
                    return // já foi cancelado no meio
                if (region === "") {
                    root.recTool = "" // slurp cancelado
                    return
                }
                recProc.command = ["wf-recorder", "-g", region, "-f", root.pendingFile]
                recProc.running = true
            }
        }
    }

    // ── PROCESSO DE GRAVAÇÃO (etapa 2) ──
    // Rastreado: wf-recorder saiu (parado, erro, morto por fora)
    // → indicador desarma sozinho. stderr vai pro log do qs.
    Process {
        id: recProc

        stderr: SplitParser {
            onRead: data => console.log("[rec]", data)
        }

        onRunningChanged: {
            if (!running && root.recTool !== "") {
                root.recTool = ""
                if (root.toolModel[root.selIndex]?.indicator)
                    root.move(-1)
            }
        }
    }

    function stopRec() {
        if (recTool === "")
            return
        recTool = ""
        // Ainda escolhendo região? Mata o slurp e pronto
        if (slurpProc.running)
            slurpProc.running = false
        // SIGINT: o wf-recorder finaliza o arquivo direitinho
        Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
        if (toolModel[selIndex]?.indicator)
            move(-1)
    }

    function run(id) {
        const entry = toolModel.find(t => t.id === id)
        const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19)
        // Monitor focado resolvido NA HORA dentro do comando
        // (Hyprland.focusedMonitor do Quickshell pode ser null)
        const out = `$(hyprctl monitors -j | jq -r '.[] | select(.focused).name')`

        // ── REC: exclusivo — iniciar um cancela o outro; repetir para.
        //  NUNCA fecha a paleta (regra do usuário) ──
        if (entry?.rec) {
            if (recTool === id) {
                stopRec()
                return
            }
            stopRec()
            recTool = id
            const file = `${Config.recordingPath}/rec-${stamp}.mp4`
            switch (id) {
            case "recCrop":
                pendingFile = file
                slurpProc.running = true // etapa 2 dispara no stdout
                break
            case "recFull":
                recProc.command = ["sh", "-c",
                    `exec wf-recorder -o "${out}" -f '${file}' < /dev/null`]
                recProc.running = true
                break
            case "recFullMic":
                recProc.command = ["sh", "-c",
                    `exec wf-recorder -a -o "${out}" -f '${file}' < /dev/null`]
                recProc.running = true
                break
            }
            return
        }

        // ── ONE-SHOTS: fecham a paleta antes (mesma regra de ouro) ──
        const shot = `${Config.screenshotPath}/shot-${stamp}.png`
        switch (id) {
        case "shotCrop":
            Quickshell.execDetached(["sh", "-c",
                `sleep 0.4; grim -g "$(slurp < /dev/null)" '${shot}' && wl-copy < '${shot}'`])
            closeRequested()
            break
        case "shotFull":
            Quickshell.execDetached(["sh", "-c",
                `sleep 0.45; grim -o "${out}" '${shot}' && wl-copy < '${shot}'`])
            closeRequested()
            break
        case "colorPicker":
            Quickshell.execDetached(["sh", "-c", "sleep 0.4; hyprpicker -a"])
            closeRequested()
            break
        case "ocr":
            Quickshell.execDetached(["sh", "-c",
                `sleep 0.4; grim -g "$(slurp < /dev/null)" /tmp/vtnc-ocr.png`
                + ` && tesseract /tmp/vtnc-ocr.png - -l por+eng 2>/dev/null | wl-copy`])
            closeRequested()
            break
        }
    }

    // ── TECLADO: setas navegam, Enter dispara, Esc fecha ──
    Item {
        id: kb

        anchors.fill: parent
        focus: root.active

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:  root.move(-1); break
            case Qt.Key_Right: root.move(1); break
            case Qt.Key_Return:
            case Qt.Key_Enter: {
                const e = root.toolModel[root.selIndex]
                if (e.indicator)
                    root.stopRec()
                else
                    root.run(e.id)
                break
            }
            case Qt.Key_Escape: root.closeRequested(); break
            default: return
            }
            event.accepted = true
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        Row {
            id: toolsRow

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5

            Repeater {
                model: root.toolModel

                Item {
                    id: tool

                    required property var modelData
                    required property int index

                    readonly property bool isSep: !!modelData.sep
                    readonly property bool isInd: !!modelData.indicator
                    readonly property bool shown: !isInd || root.recording
                    readonly property bool selected: !isSep && shown && root.selIndex === index
                    readonly property bool armed: !isSep && !isInd
                        && root.recTool === modelData.id

                    // Indicador desliza pra dentro do grupo Rec ao gravar
                    width: isSep ? 11 : (shown ? 30 : 0)
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    height: 30
                    clip: true
                    opacity: shown ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }

                    // Separador sutil entre categorias
                    Rectangle {
                        anchors.centerIn: parent
                        visible: tool.isSep
                        width: 1
                        height: 18
                        color: Theme.separator
                    }

                    // Mira: acompanha a SELEÇÃO (mouse ou setas)
                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        visible: !tool.isSep
                        color: tool.selected ? Theme.hoverLayer : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
                    }

                    // Ícone da ferramenta
                    Text {
                        anchors.centerIn: parent
                        visible: !tool.isSep && !tool.isInd
                        text: (tool.isSep || tool.isInd) ? "" : tool.modelData.icon
                        color: tool.armed ? Theme.accent : Theme.textPrimary
                        font { family: Theme.fontIcon; pixelSize: 17 }
                        Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
                    }

                    // Indicador de gravação: ponto pulsando (clique para)
                    Text {
                        anchors.centerIn: parent
                        visible: tool.isInd && root.recording
                        text: "󰑊"
                        color: Theme.danger
                        font { family: Theme.fontIcon; pixelSize: 15 }

                        SequentialAnimation on opacity {
                            running: tool.isInd && root.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
                        }
                    }

                    HoverHandler {
                        enabled: !tool.isSep && tool.shown
                        onHoveredChanged: {
                            if (hovered)
                                root.selIndex = tool.index
                        }
                    }
                    TapHandler {
                        enabled: !tool.isSep && tool.shown
                        onTapped: {
                            if (tool.isInd)
                                root.stopRec()
                            else
                                root.run(tool.modelData.id)
                        }
                    }
                }
            }
        }

        // ── LEGENDA (o "tooltip" do selecionado; Config.showTips) ──
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.showTips
            text: root.toolModel[root.selIndex]?.label ?? ""
            color: Theme.textSecondary
            font { family: Theme.fontDisplay; pixelSize: 10 }
        }
    }
}
