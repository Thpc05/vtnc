pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Config"

// ═══════════════════════════════════════════
//  ISLAND THEME — Estética só da ilha: a geometria da casca e a
//  coreografia do morph.
//
//  Nada aqui é lido por app, OSD, reveal ou módulo — se algum deles
//  precisar de um token daqui, ele deixou de ser conteúdo e virou
//  parte da ilha. Cores, fontes e o que a ilha HOSPEDA moram em
//  Config/Theme.qml; a escala de movimento, em Config/Motion.qml.
//
//  PERSISTÊNCIA: mesmo padrão do Config/Motion.qml (armadilhas do
//  FileView documentadas lá).
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var data: d
    property bool loaded: false

    // ════════════════════════════════════════
    //  COREOGRAFIA DO MORPH (ms)
    //  Entre faces: conteúdo sai → ilha morfa → conteúdo entra.
    //  INVARIANTE: morphDuration ≤ faceFadeInDelay + faceFadeIn.
    //  A ilha precisa terminar o morph enquanto os Behaviors dela
    //  ainda estão habilitados (`enabled: morphing`, ver Island.qml) —
    //  senão o tamanho salta no fim.
    // ════════════════════════════════════════
    readonly property int faceFadeOut: d.faceFadeOut
    readonly property int morphDuration: d.morphDuration
    readonly property int faceFadeInDelay: d.faceFadeInDelay
    readonly property int faceFadeIn: d.faceFadeIn

    // Escala do conteúdo na troca de face: o que sai encolhe, o que
    // entra nasce menor e assenta em 1. Sem isto o conteúdo só pisca;
    // com isto ele parece estar DENTRO da ilha que se move.
    readonly property real faceScaleOut: d.faceScaleOut
    readonly property real faceScaleIn: d.faceScaleIn

    // (a curva do assentamento é global: Config/Motion.qml)

    // ════════════════════════════════════════
    //  GEOMETRIA
    // ════════════════════════════════════════
    // DERIVADO do Theme: a ilha é o topo da linguagem de cantos, não
    // um raio próprio. Ver a seção RAIO do Config/Theme.qml
    readonly property real radius: Theme.radiusIsland

    // Distância ilha ↔ topo da tela
    readonly property real marginTop: d.marginTop

    // ════════════════════════════════════════
    //  TAMANHOS POR ESTADO
    // ════════════════════════════════════════
    readonly property real width: d.width
    readonly property real height: d.height
    readonly property real wideWidth: d.wideWidth
    readonly property real wideHeight: d.wideHeight

    // ── persistência (ver Config/Motion.qml para as armadilhas) ──
    function saveSoon() {
        if (loaded)
            saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: 100
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file

        path: Paths.island
        blockLoading: true

        onLoaded: root.loaded = true
        onLoadFailed: {
            root.loaded = true
            writeAdapter()
        }
        onAdapterUpdated: root.saveSoon()

        adapter: JsonAdapter {
            id: d

            // coreografia do morph
            property int faceFadeOut: 90
            property int morphDuration: 340
            property int faceFadeInDelay: 200
            property int faceFadeIn: 160
            property real faceScaleOut: 0.94
            property real faceScaleIn: 0.92

            // geometria (radius é derivado do Theme — não entra aqui)
            property real marginTop: 6
            property real width: 100
            property real height: 32
            property real wideWidth: 150
            property real wideHeight: 32
        }
    }
}
