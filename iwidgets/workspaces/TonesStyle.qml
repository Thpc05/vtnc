import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.services
import qs.theme
import qs.kit as K

// Workspaces "tones" (Two tones) and "tone" (Tone), 2026-10-15 (redone; caelestia's windows): each
// workspace is its label and then its windows, the focused one marked (island.workspaces.focus): a pill
// under its label and windows that slides between them, or an M3 shape under its label only, a new one
// morphing in at each change (the old Shapes style).
//  - label (island.workspaces.label): a dot, its number, a roman numeral or a Japanese numeral
//  - windows (island.workspaces.windows.<mode>): off, "icons" (the app's kind as a symbol, as caelestia)
//    or "apps" (the app's own icon); at most windows.max (0 = all)
//  - Two tones: occupied in the ink, empty weak, windows in the weak ink; the focused one in the accent on
//    an accent tint. Tone: all in the accent (empty faded); the focused one on the solid accent. With the
//    shape (under the label only) the focused one's windows are in the accent
Item {
    id: root

    required property Item ws
    // Two tones (else Tone)
    property bool two: true

    readonly property var ids: ws.range
    readonly property int activeIndex: Math.max(0, ids.indexOf(ws.activeId))
    readonly property string label: Store.island.workspaces?.label || "number"
    readonly property string windows: Store.island.workspaces?.windows?.[ws.mode] || "off"
    readonly property int maxWindows: Store.island.workspaces?.windows?.max ?? 3
    readonly property bool shapeFocus: Store.island.workspaces?.focus === "shape"

    readonly property color accent: ws.pal.accent
    readonly property color focusInk: two ? accent : ws.pal.overAccent
    readonly property color pillColor: two ? Qt.alpha(accent, 0.16) : accent

    readonly property int glyph: 14
    readonly property int spacing: 2

    // the final width (the island lays out with it) and the drawn one, following the island's curve
    readonly property real targetWidth: {
        let w = 0;
        for (let i = 0; i < rep.count; i++)
            w += rep.itemAt(i)?.targetWidth ?? 0;
        return w + Math.max(0, rep.count - 1) * spacing;
    }
    property real shownWidth: targetWidth
    Behavior on shownWidth {
        enabled: K.Kit.anim.enabled
        K.Anim {
            type: K.Anim.DefaultSpatial
        }
    }
    implicitWidth: shownWidth
    implicitHeight: 24

    function roman(n: int): string {
        const table = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
        let out = "";
        for (const [v, s] of table)
            while (n >= v) {
                out += s;
                n -= v;
            }
        return out;
    }
    function japanese(n: int): string {
        const d = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
        if (n < 10)
            return d[n];
        const tens = Math.floor(n / 10);
        return (tens > 1 ? d[tens] : "") + "十" + d[n % 10];
    }
    function labelFor(id: int): string {
        return label === "roman" ? roman(id) : label === "japanese" ? japanese(id) : String(id);
    }

    // the focused workspace's pill
    readonly property Item activeItem: (rep.count, rep.itemAt(activeIndex))
    Rectangle {
        x: root.activeItem?.x ?? 0
        y: Math.round((root.height - height) / 2)
        width: root.activeItem?.width ?? 0
        height: 22
        radius: height / 2
        color: root.pillColor
        visible: !root.shapeFocus
        Behavior on x {
            enabled: K.Kit.anim.enabled
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on width {
            enabled: K.Kit.anim.enabled
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
    }

    // or the shape under its label (a random one each time the focus moves; caelestia's)
    K.M3Shape {
        id: focusShape
        readonly property var kinds: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst", "clover4", "clover8"].filter(k => k !== shape)
        visible: root.shapeFocus
        x: (root.activeItem?.x ?? 0) + Math.round(((root.activeItem?.labelWidth ?? 22) - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: 22
        height: 22
        samples: 60
        color: root.pillColor
        Behavior on x {
            enabled: K.Kit.anim.enabled
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Connections {
            target: root
            function onActiveIndexChanged() {
                focusShape.shape = focusShape.kinds[Math.floor(Math.random() * focusShape.kinds.length)];
            }
        }
        Component.onCompleted: shape = kinds[Math.floor(Math.random() * kinds.length)]
    }

    Row {
        spacing: root.spacing

        Repeater {
            id: rep
            model: root.ids

            Item {
                id: cell
                required property int modelData
                readonly property bool active: modelData === root.ws.activeId
                readonly property bool occupied: Hypr.isOccupied(modelData)
                readonly property var tops: root.windows === "off" ? [] : Hypr.windowsOn(modelData)
                readonly property var shown: root.maxWindows > 0 ? tops.slice(0, root.maxWindows) : tops

                readonly property color ink: active ? root.focusInk : root.two ? (occupied ? root.ws.pal.over : Qt.alpha(root.ws.pal.overVariant, 0.6)) : (occupied ? root.accent : Qt.alpha(root.accent, 0.45))
                readonly property color windowInk: active ? (root.shapeFocus ? root.accent : root.focusInk) : root.two ? root.ws.pal.overVariant : Qt.alpha(root.accent, 0.8)

                // (the shape needs its whole width: the windows start after it)
                readonly property real labelWidth: Math.max(root.shapeFocus ? 24 : 0, root.label === "dot" ? 16 : Math.max(18, Math.ceil(text.implicitWidth) + 8))
                readonly property real windowsWidth: shown.length > 0 ? shown.length * root.glyph + (shown.length - 1) * 1 + 7 : 0
                readonly property real targetWidth: labelWidth + windowsWidth

                width: targetWidth
                height: root.implicitHeight
                Behavior on width {
                    enabled: K.Kit.anim.enabled
                    K.Anim {
                        type: K.Anim.FastSpatial
                    }
                }

                // the label
                Rectangle {
                    readonly property int size: cell.active ? 8 : cell.occupied ? 6 : 5
                    visible: root.label === "dot"
                    x: Math.round((cell.labelWidth - size) / 2)
                    y: Math.round((cell.height - size) / 2)
                    width: size
                    height: size
                    radius: size / 2
                    color: cell.ink
                }
                Text {
                    id: text
                    visible: root.label !== "dot"
                    width: cell.labelWidth
                    height: cell.height
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.labelFor(cell.modelData)
                    // Japanese: Noto Sans CJK JP (M3's Japanese face), a step heavier: its thin strokes read
                    // too light at this size
                    readonly property bool kanji: root.label === "japanese"
                    font.family: kanji ? "Noto Sans CJK JP" : K.Kit.clockFamily
                    font.pixelSize: 12
                    font.weight: kanji ? (cell.active || cell.occupied ? Font.Black : Font.Bold) : cell.active || cell.occupied ? Font.DemiBold : Font.Medium
                    font.features: ({
                            "tnum": 1
                        })
                    renderType: Tokens.font.renderType
                    color: cell.ink
                    Behavior on color {
                        K.CAnim {}
                    }
                }

                // its windows
                Row {
                    x: cell.labelWidth - 1
                    y: Math.round((cell.height - root.glyph) / 2)
                    spacing: 1
                    opacity: cell.windowsWidth > 0 ? 1 : 0

                    add: Transition {
                        K.Anim {
                            property: "scale"
                            from: 0
                            to: 1
                            type: K.Anim.FastSpatial
                        }
                    }

                    Repeater {
                        model: cell.shown

                        Item {
                            id: win
                            required property var modelData
                            readonly property string appId: modelData?.wayland?.appId || modelData?.lastIpcObject?.class || ""
                            readonly property var entry: appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
                            width: root.glyph
                            height: root.glyph

                            K.MaterialIcon {
                                visible: root.windows === "icons"
                                x: Math.round((parent.width - width) / 2)
                                y: Math.round((parent.height - height) / 2)
                                text: Apps.categorySymbol(win.entry?.categories ?? [])
                                size: root.glyph
                                color: cell.windowInk
                            }
                            IconImage {
                                visible: root.windows === "apps"
                                anchors.fill: parent
                                source: win.appId !== "" ? Quickshell.iconPath(win.entry?.icon || win.appId.toLowerCase(), true) : ""
                                asynchronous: true
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.focusWorkspace(cell.modelData)
                }
            }
        }
    }
}
