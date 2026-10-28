import QtQuick
import qs.core
import qs.services
import qs.theme
import qs.kit as K
import qs.dwidgets.media as DMedia

// Media "tones" (C): no button (user): the InfoRow alone, the title in the accent bold and the artist
// weak (art · title · artist · a short wave, as Island → Layout → Media switches them); a click on the
// art, title or artist plays / pauses, the wheel skips. Drawn with `pal` (the island card's for the
// Card variant).
Item {
    id: root

    property var pal: K.Kit.bare
    property var options: ({})
    // the width option (0 = auto): the info takes what's left after the button
    readonly property real fixedWidth: options.width ?? 0

    implicitWidth: fixedWidth > 0 ? fixedWidth : Math.ceil(info.implicitWidth)
    implicitHeight: 24

    DMedia.MediaState {
        id: media
        active: root.options.showWave ?? false
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => e.angleDelta.y < 0 ? MprisController.next() : MprisController.previous()
    }

    InfoRow {
        id: info
        anchors.verticalCenter: parent.verticalCenter
        media: media
        options: root.options
        available: root.fixedWidth > 0 ? root.fixedWidth : 0
        pal: root.pal
        titleColor: root.pal.accent
        artistColor: root.pal.weak
    }
}
