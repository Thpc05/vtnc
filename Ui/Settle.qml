import QtQuick
import "../Config"

// ═══════════════════════════════════════════
//  SETTLE — A animação de FORMA da shell.
//  Passa um pouco do destino e volta: é o que separa "cresceu" de
//  "assentou", e é a assinatura da ilha. Use em tudo que vira
//  tamanho — largura, altura, e os drivers 0→1 que os produzem.
//
//  Uso:  Behavior on width  { Settle {} }
//        Behavior on height { Settle { duration: 180 } }
//
//  A duração default é Motion.standard. A coreografia do morph da
//  ilha tem tempos próprios — esses vivem no Island/IslandTheme.qml.
//
//  NÃO usar em: posição (x/y — overshoot vira wobble), opacidade (o
//  Qt clampa, o overshoot só vira um hold morto) nem em tracking
//  contínuo de slider (retarget constante = tremedeira). Nesses,
//  Smooth ou um OutCubic com Motion.track.
// ═══════════════════════════════════════════
NumberAnimation {
    duration: Motion.standard
    easing.type: Easing.OutBack
    easing.overshoot: Motion.overshoot
}
