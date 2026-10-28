import QtQuick
import Quickshell.Widgets
import qs.services
import qs.kit as K
import qs.dwidgets.media as DMedia

// What the island's media styles show beside their control (Card, Disc, Two tones; 2026-10-09, user):
// the art, the title, the artist and a short wavy progress, each switched on or off per island mode in
// Island → Layout → Media (`options`: island.media.compact / expanded). `available` > 0 holds it to
// that width (the media width option): the texts elide into what's left. `media` is a dwidgets/media
// MediaState; `pal` the palette under it; `titleColor` the title's tone (the accent in Two tones).
// `art: false` for a style whose art is its own (Disc). A click on the art, the title or the artist
// plays / pauses (the wave still seeks).
Item {
    id: root

    required property var media
    property var options: ({})
    property var pal: K.Kit.bare
    property color titleColor: pal.over
    property color artistColor: pal.overVariant
    property bool art: true
    // the width it's held to (0 = its natural width, the texts up to 180 px)
    property real available: 0

    readonly property bool showArt: art && (options.showArt ?? true)
    readonly property bool showTitle: options.showTitle ?? true
    readonly property bool showArtist: (options.showArtist ?? true) && media.artist !== ""
    readonly property bool showWave: options.showWave ?? false
    readonly property int waveWidth: 44
    // the texts' weights (the mode's options; 0 / missing = 700 title, 500 artist)
    readonly property int titleWeight: (options.titleWeight ?? 0) > 0 ? options.titleWeight : 700
    readonly property int artistWeight: (options.artistWeight ?? 0) > 0 ? options.artistWeight : 500
    // what the texts may take
    readonly property real textRoom: available > 0 ? Math.max(0, available - (showArt ? 20 + row.spacing : 0) - (showWave ? waveWidth + row.spacing : 0) - (showTitle && showArtist ? row.spacing : 0)) : 180

    // its natural width from what's switched on, not the Row's: a Row doesn't lay out while it's
    // invisible, so switching a part while the media was hidden (compact showing the artist,
    // expanded not) left the old width behind (user)
    readonly property real naturalWidth: {
        const parts = [];
        if (showArt)
            parts.push(20);
        if (showTitle)
            parts.push(Math.min(titleText.implicitWidth, textRoom * (showArtist ? 0.62 : 1)));
        if (showArtist)
            parts.push(Math.min(artistText.implicitWidth, textRoom * (showTitle ? 0.38 : 1)));
        if (showWave)
            parts.push(waveWidth);
        let w = 0;
        for (const p of parts)
            w += Math.ceil(p);
        return parts.length > 0 ? w + (parts.length - 1) * row.spacing : 0;
    }
    implicitWidth: available > 0 ? available : naturalWidth
    implicitHeight: 20

    MouseArea {
        anchors.fill: row
        cursorShape: Qt.PointingHandCursor
        onClicked: MprisController.togglePlaying()
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // the art, rounded by a mask (the dashboard's Art; 2026-10-27: a ClippingRectangle at a half-pixel x,
        // as the island's width changes with the title, wrapped its picture, user)
        DMedia.Art {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showArt
            width: 20
            height: 20
            radius: K.Kit.rounding.small - 2
            source: root.media.hasArt ? root.media.artUrl : ""
            placeholder: root.pal.high
            note: root.pal.overVariant
        }
        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showTitle
            width: Math.min(implicitWidth, root.textRoom * (root.showArtist ? 0.62 : 1))
            elide: Text.ElideRight
            text: root.media.title
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 12
            font.weight: root.titleWeight
            color: root.titleColor
        }
        Text {
            id: artistText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showArtist
            width: Math.min(implicitWidth, root.textRoom * (root.showTitle ? 0.38 : 1))
            elide: Text.ElideRight
            text: root.media.artist
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 11
            font.weight: root.artistWeight
            color: root.artistColor
        }
        K.M3Slider {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showWave
            width: root.waveWidth
            height: 10
            vertical: false
            trackThickness: 2
            inactiveThickness: 2
            wavy: root.media.playing
            waveAmplitude: 1.5
            wavelength: 10
            handleShape: "circle"
            activeColor: root.pal.accent
            inactiveColor: root.pal.faint
            interactive: root.media.canSeek
            value: root.media.progress
            onMoved: v => root.media.seek(v)
        }
    }
}
