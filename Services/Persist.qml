pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Config"

// ═══════════════════════════════════════════
//  PERSIST — Estado que a SHELL escreve sozinha.
//  Acesso: Persist.state.<campo> (ler e escrever).
//
//  A FRONTEIRA que importa: aqui é o que a shell decide em runtime —
//  você nunca edita isto à mão nem versiona. Configuração (o que VOCÊ
//  escolhe, e que faz sentido copiar pra outra máquina) mora nos
//  singletons de Config/ e no Island/IslandTheme.qml, cada um no seu
//  arquivo. Por isso são arquivos separados e não um blob só.
//
//  As armadilhas do FileView/JsonAdapter estão documentadas em
//  Config/Motion.qml — valem igual aqui.
//
//  Para adicionar um dado: 1 property no JsonAdapter. O
//  `onAdapterUpdated` já cobre o save de todas.
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

        path: Paths.state
        // Estado precisa estar pronto antes dos consumidores montarem
        blockLoading: true

        onLoaded: root.loaded = true
        onLoadFailed: {
            // Arquivo ainda não existe: cria com os defaults
            root.loaded = true
            writeAdapter()
        }
        onAdapterUpdated: root.saveSoon()

        adapter: JsonAdapter {
            id: data

            // Modo da ilha (normal ↔ wide)
            property bool wideBar: false
        }
    }
}
