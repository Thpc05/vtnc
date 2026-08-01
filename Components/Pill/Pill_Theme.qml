pragma Singleton
import QtQuick

// ═══════════════════════════════════════════
//  PILL THEME — Estética só da ilha: a geometria da casca e a
//  coreografia do morph.
//
//  Nada aqui é lido por app, OSD, reveal ou módulo — se algum deles
//  precisar de um token daqui, ele deixou de ser conteúdo e virou
//  parte da ilha. Cores, fontes e o que a ilha HOSPEDA moram em
//  Components/Theme.qml.
// ═══════════════════════════════════════════
QtObject {
    // ════════════════════════════════════════
    //  COREOGRAFIA DO MORPH (ms)
    //  Entre faces: conteúdo sai → pill morfa → conteúdo entra.
    //  INVARIANTE: morphDuration ≤ faceFadeInDelay + faceFadeIn.
    //  A pill precisa terminar o morph enquanto os Behaviors dela
    //  ainda estão habilitados (`enabled: morphing`, ver Pill.qml) —
    //  senão o tamanho salta no fim.
    // ════════════════════════════════════════
    readonly property int faceFadeOut: 90
    readonly property int morphDuration: 340
    readonly property int faceFadeInDelay: 200
    readonly property int faceFadeIn: 160

    // ════════════════════════════════════════
    //  GEOMETRIA
    // ════════════════════════════════════════
    readonly property real radius: 32
    // Distância ilha ↔ topo da tela
    readonly property real marginTop: 6
    // Respiro abaixo da ilha. Hoje só compõe a altura da framed; no
    // futuro fecha a reserva de espaço da pill sozinha
    // (marginTop + height + marginDown)
    readonly property real marginDown: 6

    // ════════════════════════════════════════
    //  TAMANHOS POR ESTADO
    // ════════════════════════════════════════
    readonly property real width: 100
    readonly property real height: 32
    readonly property real wideWidth: 200
    readonly property real wideHeight: 32
}
