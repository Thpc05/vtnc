pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════
//  PERSIST — Estado da shell que sobrevive a restarts.
//  Acesso: Persist.state.<campo> (ler e escrever).
//
//  ARMADILHAS do FileView/JsonAdapter (todas custaram bug real):
//  - NUNCA `property alias` para dentro do adapter — o alias
//    re-inicializa os defaults POR CIMA dos valores carregados;
//  - auto-save só DEPOIS do load (senão a carga sobrescreve o
//    arquivo com defaults) — daí o gate `loaded` + coalesce;
//  - path SEMPRE absoluto ("~" não expande: vira um diretório
//    literal chamado "~" ao lado do cwd);
//  - Singleton é LAZY e o load aplica DEPOIS do primeiro acesso:
//    bindings se corrigem sozinhos, mas leitura IMPERATIVA em
//    Component.onCompleted pega defaults. Quem precisa ler na mão
//    usa `Connections { target: Persist; onLoadedChanged }`.
//
//  Para adicionar um dado: 1 property no JsonAdapter + 1 onChanged.
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var state: data
    property bool loaded: false

    function saveSoon() {
        if (loaded)
            saveTimer.restart()
    }

    // Coalesce: várias mudanças no mesmo tick = uma escrita só,
    // sempre do estado completo já aplicado
    Timer {
        id: saveTimer
        interval: 100
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file

        path: "/home/thpc/.local/state/vtnc/vtnc-state.json"
        // Estado precisa estar pronto antes dos consumidores montarem
        blockLoading: true

        onLoaded: root.loaded = true
        onLoadFailed: {
            // Arquivo ainda não existe: cria com os defaults
            root.loaded = true
            writeAdapter()
        }

        adapter: JsonAdapter {
            id: data

            // Modo da pill (normal ↔ wide)
            property bool wideBar: false
            // Barra de topo independente, por baixo da pill (IPC `framed`)
            property bool framed: false
            // Widgets da dashboard: pins (nome → bool) e posição no
            // grid (nome → {col, row}, em subcolunas)
            property var widgetPins: ({})
            property var widgetLayout: ({})

            onWideBarChanged: root.saveSoon()
            onFramedChanged: root.saveSoon()
            onWidgetPinsChanged: root.saveSoon()
            onWidgetLayoutChanged: root.saveSoon()
        }
    }
}
