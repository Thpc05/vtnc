pragma Singleton
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.core

// The media player the shell controls. The user can pin one (by its app identity, saved in
// Store.player.pinned): it's the target while it runs; when it closes, the last player that
// started playing takes over, and the pinned one is the target again once it comes back. Not pinned:
// the last player that started playing. Else one that plays, else the first.
Singleton {
    id: root

    // the players offered (playerctld only mirrors the others; Firefox unless enabled in System)
    readonly property var filteredPlayers: Mpris.players.values.filter(player => {
        const name = (player.dbusName || "").toLowerCase();
        if (name.includes("playerctld"))
            return false;
        return Store.media.enableFirefoxPlayer || !name.includes("firefox");
    })

    // the pinned player's identity ("" = automatic)
    readonly property string pinned: Store.player.pinned ?? ""
    // dbus names, the most recent to start playing first (this session)
    property var history: []

    readonly property var pinnedPlayer: pinned !== "" ? filteredPlayers.find(p => p.identity === pinned) ?? null : null
    readonly property var recentPlayer: {
        for (const name of history) {
            const p = filteredPlayers.find(x => x.dbusName === name);
            if (p)
                return p;
        }
        return null;
    }
    readonly property var activePlayer: pinnedPlayer ?? recentPlayer ?? filteredPlayers.find(p => p.isPlaying) ?? filteredPlayers[0] ?? null
    // (older name)
    readonly property var trackedPlayer: activePlayer

    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canChangeVolume: !!activePlayer && activePlayer.volumeSupported && activePlayer.canControl
    readonly property bool loopSupported: !!activePlayer && activePlayer.loopSupported && activePlayer.canControl
    readonly property var loopState: activePlayer ? activePlayer.loopState : MprisLoopState.None
    readonly property bool shuffleSupported: !!activePlayer && activePlayer.shuffleSupported && activePlayer.canControl
    readonly property bool hasShuffle: activePlayer?.shuffle ?? false

    // `player` started playing: first in the history
    function touch(player) {
        if (!player)
            return;
        history = [player.dbusName].concat(history.filter(n => n !== player.dbusName)).slice(0, 20);
    }

    // pin `player` (null = automatic)
    function pin(player) {
        Store.player.pinned = player ? player.identity : "";
        touch(player);
    }
    function unpin() {
        pin(null);
    }
    function setActivePlayer(player) {
        pin(player);
    }
    function cyclePlayer(direction) {
        const players = filteredPlayers;
        if (players.length === 0)
            return;
        const i = players.indexOf(activePlayer);
        pin(players[(i + (direction > 0 ? 1 : -1) + players.length) % players.length]);
    }

    function togglePlaying() {
        if (canTogglePlaying)
            activePlayer.togglePlaying();
    }
    function previous() {
        if (canGoPrevious)
            activePlayer.previous();
    }
    function next() {
        if (canGoNext)
            activePlayer.next();
    }
    function setLoopState(loopState) {
        if (loopSupported)
            activePlayer.loopState = loopState;
    }
    function setShuffle(shuffle) {
        if (shuffleSupported)
            activePlayer.shuffle = shuffle;
    }

    // a player that starts playing goes first in the history
    Instantiator {
        model: Mpris.players

        Connections {
            required property var modelData
            target: modelData

            Component.onCompleted: {
                if (modelData.isPlaying)
                    root.touch(modelData);
            }
            function onPlaybackStateChanged() {
                if (modelData.isPlaying)
                    root.touch(modelData);
            }
        }
    }
}
