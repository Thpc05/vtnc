pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.theme

// The style kit's tokens: rounding, spacing, padding, fonts and the M3 expressive motion
// (caelestia's Config/tokens.hpp), each scaled by the user's multipliers (Tokens.scale). The components in this directory (Anim, CAnim,
// StyledRect, StyledText, MaterialIcon, StateLayer) are built on these and the shell's Colors.
Singleton {
    id: root

    // the user's multipliers (Settings → Appearance → Scale; Tokens.scale)
    readonly property QtObject scale: Tokens.scale
    function sized(v: int, f: real): int {
        return Math.round(v * f);
    }
    // whole pixels only at rest (2026-10-28): rounding a position while its container moves by fractions flips
    // it back and forth by a pixel as the motion overshoots and settles (the island content trembled); while
    // moving it glides on the exact value, at rest it lands on a whole pixel (crisp text and pictures)
    function snap(v: real, atRest: bool): real {
        return atRest ? Math.round(v) : v;
    }

    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: root.sized(4, root.scale.rounding)
        readonly property int small: root.sized(8, root.scale.rounding)
        readonly property int medium: root.sized(12, root.scale.rounding)
        readonly property int large: root.sized(16, root.scale.rounding)
        readonly property int largeIncreased: root.sized(20, root.scale.rounding)
        readonly property int extraLarge: root.sized(28, root.scale.rounding)
        readonly property int extraLargeIncreased: root.sized(32, root.scale.rounding)
        readonly property int extraExtraLarge: root.sized(48, root.scale.rounding)
        readonly property int full: 100000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: root.sized(4, root.scale.spacing)
        readonly property int small: root.sized(8, root.scale.spacing)
        readonly property int medium: root.sized(12, root.scale.spacing)
        readonly property int large: root.sized(16, root.scale.spacing)
        readonly property int largeIncreased: root.sized(20, root.scale.spacing)
        readonly property int extraLarge: root.sized(28, root.scale.spacing)
        readonly property int extraLargeIncreased: root.sized(32, root.scale.spacing)
        readonly property int extraExtraLarge: root.sized(48, root.scale.spacing)
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: root.sized(4, root.scale.padding)
        readonly property int small: root.sized(8, root.scale.padding)
        readonly property int medium: root.sized(12, root.scale.padding)
        readonly property int large: root.sized(16, root.scale.padding)
        readonly property int largeIncreased: root.sized(20, root.scale.padding)
        readonly property int extraLarge: root.sized(28, root.scale.padding)
        readonly property int extraLargeIncreased: root.sized(32, root.scale.padding)
        readonly property int extraExtraLarge: root.sized(48, root.scale.padding)
    }

    // the shell's font (Tokens: Google Sans Flex unless the user picked one), drawn with
    // caelestia's rounded terminals (the ROND axis; fonts without it ignore it)
    readonly property string family: Tokens.font.family
    readonly property string monoFamily: Tokens.font.mono
    readonly property string iconFamily: "Material Symbols Rounded"
    // big numbers: the clock, workspaces (caelestia's font.clock)
    readonly property string clockFamily: "Rubik"
    readonly property var axes: ({
            "ROND": 25
        })

    function makeFont(size: int, weight: int): font {
        return Qt.font({
            family: root.family,
            pointSize: Math.max(6, Math.round(size * root.scale.font)),
            weight: weight,
            variableAxes: root.axes
        });
    }
    function monoFont(size: int): font {
        return Qt.font({
            family: root.monoFamily,
            pointSize: Math.max(6, Math.round(size * root.scale.font))
        });
    }
    function iconFont(size: int): font {
        return Qt.font({
            family: root.iconFamily,
            pointSize: Math.max(6, Math.round(size * root.scale.font))
        });
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject headline: QtObject {
            readonly property font large: root.makeFont(32, Font.Medium)
            readonly property font medium: root.makeFont(28, Font.Medium)
            readonly property font small: root.makeFont(24, Font.Medium)
        }
        readonly property QtObject title: QtObject {
            readonly property font large: root.makeFont(22, Font.Medium)
            readonly property font medium: root.makeFont(16, Font.Medium)
            readonly property font small: root.makeFont(14, Font.Medium)
        }
        readonly property QtObject body: QtObject {
            readonly property font large: root.makeFont(16, Font.Normal)
            readonly property font medium: root.makeFont(14, Font.Normal)
            readonly property font small: root.makeFont(12, Font.Normal)
        }
        readonly property QtObject label: QtObject {
            readonly property font large: root.makeFont(14, Font.Medium)
            readonly property font medium: root.makeFont(12, Font.Medium)
            readonly property font small: root.makeFont(11, Font.Normal)
        }
        readonly property QtObject mono: QtObject {
            readonly property font large: root.monoFont(16)
            readonly property font medium: root.monoFont(14)
            readonly property font small: root.monoFont(12)
        }
        readonly property QtObject icon: QtObject {
            readonly property font extraLarge: root.iconFont(Math.floor(48 / 1.33))
            readonly property font large: root.iconFont(Math.floor(32 / 1.33))
            readonly property font medium: root.iconFont(Math.floor(24 / 1.33))
            readonly property font small: root.iconFont(Math.floor(20 / 1.33))
        }
    }

    // motion: bezier curves (Easing.BezierSpline) and durations; none when the shell's animations
    // are off
    readonly property QtObject anim: QtObject {
        readonly property var emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property var standard: [0.2, 0, 0, 1, 1, 1]
        readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]

        readonly property bool enabled: root.scale.anim > 0
        // the island body overshoots its size and hops (Appearance → General → Motion → Bounce, 2026-10-28)
        readonly property bool bounce: Store.theme.anim?.bounce ?? true
        readonly property QtObject durations: QtObject {
            readonly property int small: root.sized(200, root.scale.anim)
            readonly property int normal: root.sized(400, root.scale.anim)
            readonly property int large: root.sized(600, root.scale.anim)
            readonly property int extraLarge: root.sized(1000, root.scale.anim)
            readonly property int expressiveFastSpatial: root.sized(350, root.scale.anim)
            readonly property int expressiveDefaultSpatial: root.sized(500, root.scale.anim)
            readonly property int expressiveSlowSpatial: root.sized(650, root.scale.anim)
            readonly property int expressiveFastEffects: root.sized(150, root.scale.anim)
            readonly property int expressiveDefaultEffects: root.sized(200, root.scale.anim)
            readonly property int expressiveSlowEffects: root.sized(300, root.scale.anim)
        }
    }

    // The shell's surfaces (caelestia's roles), from the page up, each through Colors.layer() so
    // they turn translucent with Appearance → Transparency:
    //   page (Colors.background: M3 surface unless mapped; the island, frame, apps) → container
    //   (cards, panes, sidebars: surfaceContainer) → off (controls, fields, chips on a container:
    //   surfaceContainerHigh) → high (a control on a control, hover rows: surfaceContainerHighest);
    //   tonal (selected / tonal buttons: secondaryContainer) and on (filled: primary).
    readonly property QtObject expressive: QtObject {
        readonly property int radius: root.rounding.large
        readonly property int pressedRadius: root.rounding.medium
        readonly property bool light: Store.theme.light
        readonly property color page: Colors.layer(Colors.background, 0)
        readonly property color container: Colors.layer(Colors.surfaceContainer, 1)
        readonly property color off: Colors.layer(Colors.surfaceContainerHigh, 2)
        readonly property color high: Colors.layer(Colors.surfaceContainerHighest, 2)
        readonly property color overOff: Colors.overSurface
        readonly property color tonal: Colors.secondaryContainer
        readonly property color overTonal: Colors.overSecondaryContainer
        readonly property color on: Colors.primary
        readonly property color overOn: Colors.overPrimary
        readonly property color track: Colors.primary
        readonly property color inactiveTrack: Colors.secondaryContainer
    }

    // The cards' palettes and the bare one, with the same roles (CardPalette.qml): fill · over /
    //   overVariant (text, icons) · accent / overAccent (a filled control: today, an on mark, a slider's
    //   fill, the play button) · off / high (a control on the fill, one step up) · tonal / overTonal (a
    //   tonal button) · selected / overSelected (a list's current row) · track (a slider's rest) · weak /
    //   faint (the two-tone styles: the accent at 55 % / 20 %).
    // A Dwidget picks `card ? K.Kit.card : K.Kit.bare`, an Iwidget gets `K.Kit.islandCard` or `K.Kit.bare`
    // from its frame (iwidgets/IwidgetFrame.qml). One colour for both since 2026-10-11 (user): Settings →
    // Appearance → General → Cards (`theme.card`); islandCard is the same palette.
    readonly property CardPalette card: CardPalette {
        kind: Store.theme?.card || "neutral"
    }
    readonly property CardPalette islandCard: card
    readonly property QtObject bare: QtObject {
        readonly property string kind: "bare"
        readonly property bool inverse: false
        readonly property color fill: "transparent"
        readonly property color over: Colors.overSurface
        readonly property color overVariant: Colors.overSurfaceVariant
        readonly property color accent: Colors.primary
        readonly property color overAccent: Colors.overPrimary
        readonly property color off: root.expressive.container
        readonly property color high: root.expressive.off
        readonly property color selected: Colors.primaryContainer
        readonly property color overSelected: Colors.overPrimaryContainer
        readonly property color tonal: Colors.secondaryContainer
        readonly property color overTonal: Colors.overSecondaryContainer
        readonly property color track: root.expressive.inactiveTrack
        readonly property color weak: Qt.alpha(accent, 0.55)
        readonly property color faint: Qt.alpha(accent, 0.2)
    }

    // The apps' look (launcher, session, tools, wallpaper; 2026-10-17): Appearance → General → Apps
    // (`theme.appStyle`), one of the Iwidgets' families, in the primary on the bare page. `appLook` has
    // the shape a Quick panel reads (look.panel, dwidgets/quick/panels/PanelColors.qml), so the apps
    // reuse the panels' pieces (ActionGroup, rows) as they are.
    readonly property string appStyle: Store.theme?.appStyle || "shapes"
    readonly property var appLook: {
        const tones = appStyle !== "shapes";
        return {
            panel: {
                kind: appStyle,
                pal: bare,
                tone: Colors.primary,
                overTone: Colors.overPrimary,
                strong: tones ? Colors.primary : bare.over,
                weak: tones ? Qt.alpha(Colors.primary, expressive.light ? 0.85 : 0.62) : bare.overVariant,
                randomShapes: false,
                faint: Qt.alpha(tones ? Colors.primary : bare.over, 0.1)
            }
        };
    }

    function clamp(v: real, lo: real, hi: real): real {
        return Math.max(lo, Math.min(hi, v));
    }
}
