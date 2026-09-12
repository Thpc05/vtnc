import QtQuick

// ═══════════════════════════════════════════
//  SMOOTH — A animação de POSIÇÃO/OPACIDADE da shell.
//  Chega e para, sem passar do alvo. O par do Settle: onde o
//  overshoot seria errado (x/y viram wobble; opacidade o Qt clampa),
//  é este que entra.
//
//  Uso:  Behavior on x       { Smooth {} }
//        Behavior on opacity { Smooth { duration: Motion.quick } }
// ═══════════════════════════════════════════
NumberAnimation {
    duration: Motion.standard
    easing.type: Easing.OutQuart
}
