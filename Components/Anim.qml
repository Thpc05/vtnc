import QtQuick

// ═══════════════════════════════════════════
//  ANIM — A animação padrão da shell.
//  OutBack com overshoot = Theme.bounce: um knob só controla o
//  "pulo" de todas as animações (overshoot 0 = OutCubic exato).
//
//  Uso:  Behavior on width { Anim {} }
//        Behavior on height { Anim { duration: 150 } }
//
//  NÃO usar em: tracking contínuo de slider (retarget a cada evento
//  vira tremedeira — usar OutCubic curto) nem em fade de opacity.
// ═══════════════════════════════════════════
NumberAnimation {
    duration: Theme.animDuration
    easing.type: Easing.OutBack
    easing.overshoot: Theme.bounce
}
