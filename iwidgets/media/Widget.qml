import QtQuick
import qs.core
import qs.services
import qs.kit as K

// The island's media player (stage 7, 2026-10-08; 2026-10-09 redo). Styles:
//  - default (CompactPlayer; was "Card", 2026-10-09): a small art with the title and artist
//  - disc: a small round art turning while playing and the title beside it
//  - tones: the title in the accent bold and the artist weak
// Its options are per island mode (island.media.compact / expanded, Island → Layout → Media, two
// columns): what it shows (art, title, artist, a short wave: InfoRow.qml), the controls after it
// (MediaControls.qml, 2026-10-15: an option of every style, was the "controls" style) and its width
// (0 = auto; with the controls it's the whole). Every style also comes on the island card (Card
// variants: `pal`). A click on the art / title plays or pauses; the wheel skips.
// When it goes away (island.media.visibility, 2026-10-15): "never" (a note icon without a player),
// "noMedia" (collapses to 0 without a player) or "paused" (also while paused, after a moment so a track
// change doesn't blink it).
Item {
    id: root

    property string style: "default"
    // from the frame: the palette (the island card's for the Card variants, or the bare island's)
    property var pal: K.Kit.bare
    property string mode: "compact"
    // this mode's options (showArt / showTitle / showArtist / showWave / controls / width)
    readonly property var options: Store.island.media?.[mode] ?? ({})
    readonly property bool controls: options.controls ?? false

    readonly property string visibility: Store.island.media?.visibility || "noMedia"
    readonly property var player: MprisController.activePlayer
    readonly property bool playing: player?.isPlaying ?? false
    // paused for longer than a track change
    property bool pausedAWhile: !playing
    onPlayingChanged: {
        if (playing) {
            pauseGrace.stop();
            pausedAWhile = false;
        } else {
            pauseGrace.restart();
        }
    }
    Timer {
        id: pauseGrace
        interval: 1500
        onTriggered: root.pausedAWhile = !root.playing
    }
    readonly property bool showPlayer: player !== null && !(visibility === "paused" && pausedAWhile)
    readonly property bool showIcon: player === null && visibility === "never"

    readonly property real gap: K.Kit.spacing.small
    // with a fixed width the controls come out of it (the style's texts shorten)
    readonly property var viewOptions: controls && (options.width ?? 0) > 0 ? Object.assign({}, options, {
        width: Math.max(0, options.width - mediaControls.implicitWidth - gap)
    }) : options

    implicitWidth: showPlayer ? (view.item?.implicitWidth ?? 0) + (controls ? gap + mediaControls.implicitWidth : 0) : showIcon ? 20 : 0
    implicitHeight: 24

    Loader {
        id: view
        anchors.verticalCenter: parent.verticalCenter
        active: root.showPlayer
        sourceComponent: root.style === "disc" ? disc : root.style === "tones" ? tones : compact
    }

    MediaControls {
        id: mediaControls
        x: (view.item?.implicitWidth ?? 0) + root.gap
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showPlayer && root.controls
        pal: root.pal
        // the style's colours: Two tones in the accent
        ink: root.style === "tones" ? root.pal.accent : root.pal.over
        activeInk: root.pal.accent
        offInk: root.style === "tones" ? root.pal.weak : root.pal.overVariant
    }

    // nothing playing ("never"): a note
    K.MaterialIcon {
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        visible: root.showIcon
        text: "music_note"
        size: 18
        color: root.pal.overVariant
    }

    Component {
        id: compact
        CompactPlayer {
            options: root.viewOptions
            player: MprisController.activePlayer
            pal: root.pal
        }
    }
    Component {
        id: disc
        DiscView {
            options: root.viewOptions
            pal: root.pal
        }
    }
    Component {
        id: tones
        TonesView {
            options: root.viewOptions
            pal: root.pal
        }
    }
}
