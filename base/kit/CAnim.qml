import QtQuick

// Color changes: slow effects.
ColorAnimation {
    duration: Kit.anim.durations.expressiveSlowEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Kit.anim.expressiveSlowEffects
}
