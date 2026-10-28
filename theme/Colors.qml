pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import "colorRoles.js" as Roles

// The shell's color tokens. matugen's whole output (every role of both schemes and the tonal
// palettes, written by Wallpapers to ~/.cache/vtnc/matugen.json) is mapped to each token by
// theme/colorRoles.js: by default its M3 role in the current mode (background: M3 surface),
// or what the user picked in Settings → Appearance → Colors (Store.theme.colors[mode][token]: a
// role of either scheme, a palette tone or a fixed hex). Until matugen has run, a fallback palette.
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/vtnc/matugen.json"
    readonly property string mode: Store.theme.light ? "light" : "dark"

    // the parsed matugen output (the last good one)
    property var data: null

    // `token`'s hex in the current mode
    function resolveToken(token: string): string {
        return resolveFor(mode, token);
    }
    // `token`'s hex in `m` with `spec` (the settings preview; undefined = the user's mapping). A token
    // that `follows` another (frame → background) is that one's colour while it has no spec
    function resolveFor(m: string, token: string, spec): string {
        const s = spec === undefined ? Store.theme.colors?.[m]?.[token] : spec;
        const follows = Roles.BY_TOKEN[token]?.follows;
        if (follows && !s)
            return resolveFor(m, follows);
        return Roles.resolve(data, m, token, s);
    }
    // a spec's hex in `m` ("" when it doesn't resolve)
    function specHex(m: string, spec: string): string {
        return Roles.specHex(data, m, spec);
    }

    readonly property string primary: resolveToken("primary")
    readonly property string overPrimary: resolveToken("overPrimary")
    readonly property string primaryContainer: resolveToken("primaryContainer")
    readonly property string overPrimaryContainer: resolveToken("overPrimaryContainer")
    readonly property string secondary: resolveToken("secondary")
    readonly property string overSecondary: resolveToken("overSecondary")
    readonly property string secondaryContainer: resolveToken("secondaryContainer")
    readonly property string overSecondaryContainer: resolveToken("overSecondaryContainer")
    readonly property string tertiary: resolveToken("tertiary")
    readonly property string overTertiary: resolveToken("overTertiary")
    readonly property string tertiaryContainer: resolveToken("tertiaryContainer")
    readonly property string overTertiaryContainer: resolveToken("overTertiaryContainer")
    readonly property string background: resolveToken("background")
    readonly property string tintedBackground: resolveToken("tintedBackground")
    // the screen frame and corners (Auto: the background)
    readonly property string frame: resolveToken("frame")
    readonly property string surface: resolveToken("surface")
    readonly property string surfaceDim: resolveToken("surfaceDim")
    readonly property string surfaceBright: resolveToken("surfaceBright")
    readonly property string surfaceContainerLowest: resolveToken("surfaceContainerLowest")
    readonly property string surfaceContainerLow: resolveToken("surfaceContainerLow")
    readonly property string surfaceContainer: resolveToken("surfaceContainer")
    readonly property string surfaceContainerHigh: resolveToken("surfaceContainerHigh")
    readonly property string surfaceContainerHighest: resolveToken("surfaceContainerHighest")
    readonly property string surfaceVariant: resolveToken("surfaceVariant")
    readonly property string inverseSurface: resolveToken("inverseSurface")
    readonly property string overInverseSurface: resolveToken("overInverseSurface")
    readonly property string inversePrimary: resolveToken("inversePrimary")
    readonly property string overBackground: resolveToken("overBackground")
    readonly property string overSurface: resolveToken("overSurface")
    readonly property string overSurfaceVariant: resolveToken("overSurfaceVariant")
    readonly property string outline: resolveToken("outline")
    readonly property string outlineVariant: resolveToken("outlineVariant")
    readonly property string shadow: resolveToken("shadow")
    readonly property string scrim: resolveToken("scrim")
    readonly property string error: resolveToken("error")
    readonly property string overError: resolveToken("overError")
    readonly property string errorContainer: resolveToken("errorContainer")
    readonly property string overErrorContainer: resolveToken("overErrorContainer")

    // Extra tokens used by the compat-based code
    readonly property color green: "#b7d085"
    readonly property color red: "#ffb4ab"
    readonly property color yellow: "#dec56e"
    readonly property color warning: yellow
    readonly property color success: green
    readonly property color criticalText: "#FF6B08"
    readonly property color criticalRed: "#FF0028"

    // Transparency (Appearance → Transparency; caelestia's Colours.layer, ported). Off: every
    // color is opaque. On: the page (layer 0) takes `base` alpha, and each layer above takes
    // `layers` alpha, lifted (darkened in light mode) so it still reads over the blurred page; the
    // lift grows with the wallpaper's luminance (matugen.json `luminance`, Wallpapers). Hyprland
    // blurs what is behind (services/Hypr.qml syncs its layer rules).
    readonly property QtObject transparency: QtObject {
        readonly property bool enabled: Store.theme.transparency?.enabled ?? false
        readonly property real base: Math.max(0, Math.min(1, (Store.theme.transparency?.base ?? 0.85) - (root.mode === "light" ? 0.1 : 0)))
        readonly property real layers: Math.max(0, Math.min(1, Store.theme.transparency?.layers ?? 0.4))
    }
    readonly property real wallLuminance: typeof data?.luminance === "number" ? data.luminance : 0

    function luminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }
    function lift(c: color, a: real, layer: int): color {
        const light = mode === "light";
        const lum = luminance(c);
        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        // pure black has no luminance to scale: lift it as a grey
        if (lum === 0)
            return Qt.rgba(Math.max(0, offset), Math.max(0, offset), Math.max(0, offset), a);
        const k = (lum + offset) / lum;
        return Qt.rgba(Math.max(0, Math.min(1, c.r * k)), Math.max(0, Math.min(1, c.g * k)), Math.max(0, Math.min(1, c.b * k)), a);
    }
    // `c` as a surface at `layer` (0 = the page, 1 = a container, 2 = on a container)
    function layer(c: color, layer: int): color {
        if (!transparency.enabled)
            return c;
        return layer === 0 ? Qt.alpha(c, transparency.base) : lift(c, transparency.layers, layer ?? 1);
    }

    // Color with alpha, e.g. Colors.alpha(Colors.primary, 0.2)
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors)
                    root.data = d;
            } catch (e) {
                console.warn("[Colors] bad", root.path, e);
            }
        }
    }
}
