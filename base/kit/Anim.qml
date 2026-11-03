import QtQuick

// A NumberAnimation on one of the M3 motion tokens (Kit.anim), picked by `type`.
NumberAnimation {
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
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects,
        // the island body's size and everything moving with it: DefaultSpatial's, with its overshoot only while
        // Appearance → General → Motion → Bounce is on (Kit.anim.bounce, 2026-10-28), else emphasized decelerate
        BodySpatial
    }

    property int type: Anim.DefaultSpatial

    duration: {
        const d = Kit.anim.durations;
        if (type < Anim.StandardSmall || type > Anim.BodySpatial)
            return d.normal;
        if (type === Anim.BodySpatial)
            return d.expressiveDefaultSpatial;
        if (type === Anim.FastSpatial)
            return d.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return d.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return d.expressiveSlowSpatial;
        if (type === Anim.FastEffects)
            return d.expressiveFastEffects;
        if (type === Anim.DefaultEffects)
            return d.expressiveDefaultEffects;
        if (type === Anim.SlowEffects)
            return d.expressiveSlowEffects;
        return d[["small", "normal", "large", "extraLarge"][type % 4]];
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        const a = Kit.anim;
        if (type === Anim.BodySpatial)
            return a.bounce ? a.expressiveDefaultSpatial : a.emphasizedDecel;
        if (type === Anim.FastSpatial)
            return a.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return a.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return a.expressiveSlowSpatial;
        if (type === Anim.FastEffects)
            return a.expressiveFastEffects;
        if (type === Anim.DefaultEffects)
            return a.expressiveDefaultEffects;
        if (type === Anim.SlowEffects)
            return a.expressiveSlowEffects;
        if (type >= Anim.EmphasizedSmall && type <= Anim.EmphasizedExtraLarge)
            return a.emphasized;
        return a.standard;
    }
}
