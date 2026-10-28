import QtQuick
import qs.core
import qs.services
import qs.components
import qs.theme
import qs.kit as K

// OSD transient: the island becomes a level bar. The bar's length IS the percentage
// (osd.pxPerPercent px per 1 %, past 100 % too, up to audio.maxVolume), symmetric, with the icon
// on its left and the percentage on its right. Everything is placed around the centre, so the
// bar's middle is always the island's middle while it grows or shrinks.
// With osd.fitIsland the scale comes from the island instead: 100 % is exactly as wide as the
// island was (compact or expanded, `islandWidth` from Island).
// At 0 % or muted it folds into a perfect circle (islandPill) with just the mute icon.
// payload: { type: "volume" | "mic" | "brightness", value: 0..1 (volume: 0..limit), muted }.
// Updates arrive in place.
Item {
    id: root

    property var payload: ({})
    // the idle island's width before this transient (set by Island)
    property real islandWidth: 0
    readonly property bool islandCentered: true
    // radius = half the height: with the width equal to the height it's a circle
    readonly property bool islandPill: true

    readonly property string type: payload?.type ?? "volume"
    readonly property real maxValue: type === "volume" ? Audio.maxValue : 1
    readonly property real value: Math.max(0, Math.min(maxValue, payload?.value ?? 0))
    readonly property bool muted: payload?.muted ?? false
    // nothing to show but the icon
    readonly property bool off: muted || Math.round(value * 100) <= 0

    readonly property real padding: 12
    readonly property real gap: 10
    readonly property real pxPerPercent: {
        if (Store.osd.fitIsland && islandWidth > 0)
            return Math.max(0.2, (islandWidth - 2 * padding - 2 * side - 2 * gap) / 100);
        return Store.osd.pxPerPercent > 0 ? Store.osd.pxPerPercent : 1.4;
    }
    // wide enough for the icon and for "100%"
    readonly property real side: Math.max(20, Math.ceil(widest.advanceWidth))

    // final sizes (the island sizes to them); `barWidth` / `spread` follow with the content curve
    readonly property real targetBarWidth: off ? 0 : Math.round(value * 100) * pxPerPercent
    readonly property real targetSpread: off ? 0 : 1
    property real barWidth: targetBarWidth
    property real spread: targetSpread
    Component.onCompleted: {
        barWidth = targetBarWidth;
        spread = targetSpread;
    }
    onTargetBarWidthChanged: animateTo(barAnim, "barWidth", targetBarWidth)
    onTargetSpreadChanged: animateTo(spreadAnim, "spread", targetSpread)
    // the island body's curve (K.Anim BodySpatial, R1 2026-10-11; was ContentAnim)
    function animateTo(anim, property: string, to: real) {
        if (!K.Kit.anim.enabled || !visible) {
            anim.stop();
            root[property] = to;
            return;
        }
        anim.to = to;
        anim.restart();
    }
    K.Anim {
        id: barAnim
        target: root
        property: "barWidth"
        type: K.Anim.BodySpatial
    }
    K.Anim {
        id: spreadAnim
        target: root
        property: "spread"
        type: K.Anim.BodySpatial
    }

    implicitHeight: Store.island.height
    implicitWidth: off ? implicitHeight : 2 * padding + 2 * side + 2 * gap + targetBarWidth

    // distance from the centre to the middle of each side box
    readonly property real reach: spread * (barWidth / 2 + gap + side / 2)

    TextMetrics {
        id: widest
        font: percent.font
        text: "100%"
    }

    Icon {
        x: root.width / 2 - root.reach - width / 2
        anchors.verticalCenter: parent.verticalCenter
        size: 18
        // filled while there's a level, outlined when off (M3's on / off)
        fill: root.off ? 0 : 1
        icon: root.type === "volume" ? Audio.volumeIcon(root.value, root.off) : (root.type === "mic" ? (root.off ? Icons.micSlash : Icons.mic) : Icons.sun)
        color: Colors.overBackground
        // the sun turns and grows with the brightness
        rotation: root.type === "brightness" ? root.value * 180 : 0
        scale: root.type === "brightness" ? 0.8 + root.value * 0.2 : 1
        Behavior on rotation {
            K.Anim {
                type: K.Anim.BodySpatial
            }
        }
        Behavior on scale {
            K.Anim {
                type: K.Anim.BodySpatial
            }
        }
    }

    // the level: a pill as long as the percentage, growing from the centre, in the kit's M3
    // slider colors and thickness (K.M3Slider's active track: half of its 16 px cross size)
    K.StyledRect {
        x: (root.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.barWidth
        height: 8
        radius: height / 2
        color: K.Kit.expressive.track
        visible: width > 0.5
    }

    StyledText {
        id: percent
        x: root.width / 2 + root.reach - width / 2
        width: root.side
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: `${Math.round(root.value * 100)}%`
        font.pixelSize: Tokens.font.small
        font.weight: Font.DemiBold
        opacity: root.spread
        visible: opacity > 0.01
    }
}
