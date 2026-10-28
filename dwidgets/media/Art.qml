import QtQuick
import QtQuick.Effects
import qs.theme
import qs.kit as K

// The cover art, rounded by a mask (`radius`; half the size = a disc), optionally blurred; a note
// on a container when there's none. `spin` turns the picture inside the still mask (the disc, 2026-10-27:
// turning the masked item itself resampled its rim each frame, jagged and crawling, user).
Item {
    id: root

    property string source
    property real radius: K.Kit.rounding.large
    // 0…1: a blurred backdrop
    property real blur: 0
    property color placeholder: K.Kit.expressive.high
    property color note: Colors.overSurfaceVariant
    property bool showNote: true
    // degrees: the picture turns, the mask (and its rim) stays
    property real spin: 0
    readonly property bool ready: image.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        visible: !root.ready
        radius: root.radius
        color: root.placeholder
    }
    K.MaterialIcon {
        anchors.centerIn: parent
        visible: !root.ready && root.showNote
        text: "music_note"
        size: Math.max(12, Math.min(root.width, root.height) * 0.35)
        color: root.note
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    // the picture turning inside, drawn into one layer that the still mask cuts
    Item {
        id: picture
        anchors.fill: parent
        visible: root.ready
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
            blurEnabled: root.blur > 0
            blur: root.blur
            blurMax: 64
            autoPaddingEnabled: false
        }

        Image {
            id: image
            anchors.fill: parent
            rotation: root.spin
            smooth: true
            antialiasing: true
            // loaded near its size on screen (2×) and mipmapped (2026-10-27: a ~600 px cover drawn at 22 px
            // sampled a few of its pixels, a different few each frame as it turned: the centre shimmered)
            mipmap: true
            // (a power of two ≥ 2× the size: a size animating doesn't reload it every frame; the mipmaps do the rest)
            sourceSize: {
                const side = Math.pow(2, Math.ceil(Math.log2(Math.max(16, Math.max(root.width, root.height) * 2))));
                return Qt.size(side, side);
            }
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
