import QtQuick

// An AnchorAnimation on one of the M3 motion tokens (Kit.anim), picked by `type` (the spatial
// subset of Anim's types).
AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: {
        const d = Kit.anim.durations;
        if (type === AnchorAnim.FastSpatial)
            return d.expressiveFastSpatial;
        if (type === AnchorAnim.SlowSpatial)
            return d.expressiveSlowSpatial;
        if (type < AnchorAnim.StandardSmall || type >= AnchorAnim.FastSpatial)
            return d.expressiveDefaultSpatial;
        return d[["small", "normal", "large", "extraLarge"][type % 4]];
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        const a = Kit.anim;
        if (type === AnchorAnim.FastSpatial)
            return a.expressiveFastSpatial;
        if (type === AnchorAnim.SlowSpatial)
            return a.expressiveSlowSpatial;
        if (type >= AnchorAnim.StandardSmall && type <= AnchorAnim.StandardExtraLarge)
            return a.standard;
        if (type >= AnchorAnim.EmphasizedSmall && type <= AnchorAnim.EmphasizedExtraLarge)
            return a.emphasized;
        return a.expressiveDefaultSpatial;
    }
}
