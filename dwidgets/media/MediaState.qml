import QtQuick
import qs.services

// What every media style reads: the active player (MprisController: Automatic or the pinned one),
// its position (Mpris doesn't push it: polled while playing and `active`), the texts, the art, and
// the time format.
Item {
    id: root

    // poll the position (the style is shown)
    property bool active: true

    readonly property var player: MprisController.activePlayer
    readonly property bool playing: MprisController.isPlaying
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property bool canSeek: player?.canSeek ?? false
    readonly property string title: player ? (player.trackTitle || "Unknown") : "Nothing playing"
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string identity: player?.identity ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property bool hasArt: probe.status === Image.Ready

    visible: false

    Timer {
        interval: 1000
        running: root.playing && root.active
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
    // loads the art once to know whether there is one
    Image {
        id: probe
        source: root.artUrl
        asynchronous: true
        sourceSize: Qt.size(64, 64)
    }

    function time(s: real): string {
        if (!(s > 0))
            return "0:00";
        const m = Math.floor(s / 60);
        const sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    function seek(v: real) {
        if (player && canSeek)
            player.position = v * length;
    }
}
