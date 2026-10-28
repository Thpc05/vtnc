import QtQuick
import qs.core
import qs.services
import qs.theme
import qs.kit as K
import qs.dwidgets.media as DMedia

// Media "disc" (B): a small round art turning while playing (the dashboard disc's sibling), then the
// InfoRow (title · artist · a short wave, as Island → Layout → Media switches them; the disc is the
// art; with Art off it's a plain disc with play / pause, turning too). A click plays / pauses, the
// wheel skips.
Item {
    id: root

    property var pal: K.Kit.bare
    property var options: ({})
    readonly property real fixedWidth: options.width ?? 0
    // art off: the disc without the image, a play / pause glyph on it (turning with it)
    readonly property bool showArt: options.showArt ?? true

    implicitWidth: fixedWidth > 0 ? fixedWidth : art.width + (info.implicitWidth > 0 ? K.Kit.spacing.small + Math.ceil(info.implicitWidth) : 0)
    implicitHeight: 24

    DMedia.MediaState {
        id: media
        active: root.options.showWave ?? false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: MprisController.togglePlaying()
        onWheel: w => w.angleDelta.y < 0 ? MprisController.next() : MprisController.previous()
    }

    // the disc: the dashboard's Art (a still circle mask, the picture turning inside it; 2026-10-27: a turning
    // clip had a jagged rim, and a ClippingRectangle at a half-pixel x, as the island's width changes with the
    // title, wrapped its picture: the right edge showed at the left, user). Art off (or none): the play / pause
    // glyph turning on a plain disc
    Item {
        id: art
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22

        // turns while playing; resumes where it stopped
        property real spin: 0
        NumberAnimation on spin {
            running: media.playing && K.Kit.anim.enabled
            loops: Animation.Infinite
            from: art.spin
            to: art.spin + 360
            duration: 8000
        }

        DMedia.Art {
            anchors.fill: parent
            visible: media.hasArt && root.showArt
            radius: width / 2
            source: media.hasArt && root.showArt ? media.artUrl : ""
            spin: art.spin
            placeholder: root.pal.off
            note: root.pal.overVariant
        }
        Rectangle {
            anchors.fill: parent
            visible: !media.hasArt || !root.showArt
            radius: width / 2
            color: root.pal.off

            K.MaterialIcon {
                anchors.centerIn: parent
                rotation: art.spin
                text: root.showArt ? "music_note" : media.playing ? "pause" : "play_arrow"
                size: 14
                fill: root.showArt ? 0 : 1
                color: root.pal.overVariant
            }
        }
    }

    InfoRow {
        id: info
        x: art.width + K.Kit.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        media: media
        options: root.options
        available: root.fixedWidth > 0 ? Math.max(0, root.fixedWidth - art.width - K.Kit.spacing.small) : 0
        pal: root.pal
        art: false
    }
}
