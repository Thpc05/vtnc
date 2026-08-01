pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// ═══════════════════════════════════════════
//  MEDIA SERVICE — Fonte única de verdade da mídia (MPRIS).
//  Todo consumidor (MediaWidget, MediaReveal, Media, Visualizer,
//  Center) lê daqui — é o que faz o seletor de fonte valer pra todos
//  ao mesmo tempo. Ninguém toca em `Mpris.players.values[0]`.
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var players: Mpris.players.values

    // Escolha manual (null = automático). Guardada como var: se o
    // player escolhido fechar, o fallback assume sozinho.
    property var selected: null

    // AUTO + MANUAL: a escolha manual vale enquanto o player existir;
    // sem escolha, prefere quem está TOCANDO (zen pausado + spotify
    // tocando → spotify); ninguém tocando → o primeiro da lista.
    readonly property var active: {
        if (selected && players.indexOf(selected) >= 0)
            return selected
        const playing = players.find(
            p => p.playbackState === MprisPlaybackState.Playing)
        return playing ?? players[0] ?? null
    }

    readonly property bool hasPlayer: active !== null
    readonly property bool hasChoice: players.length > 1

    readonly property bool isPlaying: active
        ? (active.playbackState === MprisPlaybackState.Playing)
        : false

    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""
    readonly property real length: active?.length ?? 0

    // ── Progresso ──
    // A position do MPRIS não "anda" sozinha: só reporta quando
    // perguntada. O tick puxa enquanto toca.
    property int _tick: 0
    Timer {
        running: root.isPlaying
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }
    readonly property real position: {
        _tick // dependência: re-lê a cada tick
        return active?.position ?? 0
    }
    readonly property real progress:
        (length > 0) ? Math.min(1, position / length) : 0

    // ── Controles (encaminham pro player ativo) ──
    function toggle() { active?.togglePlaying() }
    function next() { active?.next() }
    function previous() { active?.previous() }

    // ── Seleção de fonte ──
    function select(p) { selected = p }
    function cycle() {
        if (players.length === 0)
            return
        const i = active ? players.indexOf(active) : -1
        selected = players[(i + 1) % players.length]
    }

    // Glyph/nome da fonte (pro chip do seletor)
    function sourceIcon(p) {
        if (!p)
            return "󰝚"
        const id = ((p.identity ?? "") + " " + (p.dbusName ?? "")).toLowerCase()
        if (id.includes("spotify")) return ""
        if (id.includes("zen") || id.includes("firefox")) return "󰈹"
        if (id.includes("chrom") || id.includes("brave") || id.includes("edge")) return ""
        if (id.includes("mpv")) return ""
        if (id.includes("vlc")) return "󰕼"
        if (id.includes("youtube")) return ""
        return "󰝚"
    }
    function sourceName(p) {
        return p ? (p.identity && p.identity !== "" ? p.identity : p.dbusName) : "—"
    }
}
