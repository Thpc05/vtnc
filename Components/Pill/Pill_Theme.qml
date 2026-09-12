pragma Singleton
import QtQuick
import ".."

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

    // A dashboard NÃO passa pela coreografia de troca de face: ela
    // cresce direto, dentro da própria bar. Mas precisa PARAR no mesmo
    // instante que um app pararia, senão parece disparada do lado
    // deles. O morph de um app só começa depois do fade de saída — daí
    // a soma. Derivado, não calibrado na mão: mexer em qualquer um dos
    // dois reajusta a dashboard sozinho
    readonly property int dashDuration: faceFadeOut + morphDuration

    // (a curva do assentamento é global: Components/Motion.qml)

    // Escala do conteúdo na troca de face: o que sai encolhe, o que
    // entra nasce menor e assenta em 1. Sem isto o conteúdo só pisca;
    // com isto ele parece estar DENTRO da ilha que se move.
    readonly property real faceScaleOut: 0.94
    readonly property real faceScaleIn: 0.92

    // ════════════════════════════════════════
    //  GEOMETRIA
    // ════════════════════════════════════════
    // Canto da ilha — CONSTANTE, igual em toda altura. Não deriva mais
    // da altura: o canto mudar durante a abertura é o que incomodava.
    // O min(altura/2, ...) na Pill continua, mas só como piso de
    // segurança (o Qt clamparia de qualquer jeito)
    readonly property real radius: Theme.radiusIsland
    // Distância ilha ↔ topo da tela
    readonly property real marginTop: 6

    // ════════════════════════════════════════
    //  TAMANHOS POR ESTADO
    // ════════════════════════════════════════
    readonly property real width: 100
    readonly property real height: 32
    readonly property real wideWidth: 150
    readonly property real wideHeight: 32
}
