pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Design tokens. Values that the user can change come from Store.theme.
Singleton {
    id: root

    // the user's multipliers (Store.theme.scale; 1 = factory). The kit (kit/Kit.qml) reads these too
    readonly property QtObject scale: QtObject {
        readonly property real rounding: root.validScale(Store.theme.scale?.rounding)
        readonly property real spacing: root.validScale(Store.theme.scale?.spacing)
        readonly property real padding: root.validScale(Store.theme.scale?.padding)
        readonly property real font: Math.max(0.5, root.validScale(Store.theme.scale?.font))
        // 0 = animations off
        readonly property real anim: Math.max(0, Store.theme.scale?.anim ?? 1)
    }
    function validScale(v): real {
        return typeof v === "number" && v >= 0 ? v : 1;
    }

    // the base corner radius (16 px at scale 1, as Kit.rounding.large)
    readonly property int roundness: Math.round(16 * scale.rounding)

    function radius(offset: int): int {
        return Math.max(0, roundness + (offset ?? 0));
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: Math.round(4 * root.scale.spacing)
        readonly property int s: Math.round(8 * root.scale.spacing)
        readonly property int m: Math.round(12 * root.scale.spacing)
        readonly property int l: Math.round(16 * root.scale.spacing)
        readonly property int xl: Math.round(24 * root.scale.spacing)
    }

    // the shell's font: M3 Expressive's Google Sans Flex (ttf-google-sans-flex-variable) unless
    // the user picked one in Appearance (theme.font); Roboto without either
    readonly property string defaultFamily: {
        const all = Qt.fontFamilies();
        for (const f of ["Google Sans Flex", "GoogleSansFlex"])
            if (all.includes(f))
                return f;
        return "Roboto";
    }

    readonly property QtObject font: QtObject {
        readonly property string family: Store.theme.font || root.defaultFamily
        readonly property string mono: Store.theme.monoFont
        readonly property string icon: Icons.font
        readonly property int base: Math.round(14 * root.scale.font)

        readonly property int small: base - 2
        readonly property int normal: base
        readonly property int large: base + 2
        readonly property int title: base + 6
        // how every text and icon glyph is drawn. Native: hinted, on the pixel grid (sharpest).
        // Qt (distance fields): at subpixel positions, moves smoothly, a little softer. Native,
        // with the island's content kept at a constant screen position (Island.qml bodyLayer)
        readonly property int renderType: Text.NativeRendering
    }

    // Old animation vocabulary (fades → OutQuart, reveal/slide → OutCubic); what's left of it moves to
    // K.Anim area by area (Stage R1)
    readonly property QtObject anim: QtObject {
        // the island's motion (450 ms at scale 1)
        readonly property int duration: Math.round(450 * root.scale.anim)
        readonly property int fast: duration / 2
        readonly property int faster: duration / 4
        readonly property int fadeEasing: Easing.OutQuart
        readonly property int slideEasing: Easing.OutCubic
    }

}
