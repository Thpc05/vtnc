#!/usr/bin/env python3
# Builds an offscreen probe: a tiny Quickshell config that loads the shell's real kit/, components/,
# dwidgets/ and iwidgets/ (symlinks, read only) on stubs: theme/Colors.qml with the user's matugen palette,
# the real Tokens / Icons, a read-only core/Store.qml and a fake player. Nothing is written in the shell.
#
#   python3 -I tools/probe/mkprobe.py <probe dir> [dark|light]
#
# The probe dir must be OUTSIDE the shell's code (the script refuses otherwise) and is marked with
# `.vtnc-probe`; an existing non-empty dir without that mark is refused too. Usually run through
# render.sh, which also calls mkisland.py (the island stubs). See README.md.
import json, os, re, sys

# the shell the tools sit in (the dev worktree), unless VTNC names another
VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MARK = ".vtnc-probe"

if len(sys.argv) < 2:
    sys.exit("usage: mkprobe.py <probe dir> [dark|light]")
out = os.path.realpath(sys.argv[1])
mode = "light" if len(sys.argv) > 2 and sys.argv[2] == "light" else "dark"

# never inside the shell, never someone else's folder
if out == VTNC or out.startswith(VTNC + os.sep):
    sys.exit(f"refused: {out} is inside the shell's code ({VTNC})")
if os.path.isdir(out) and os.listdir(out) and not os.path.exists(os.path.join(out, MARK)):
    sys.exit(f"refused: {out} is not empty and is not a probe dir (no {MARK})")
os.makedirs(out, exist_ok=True)
open(os.path.join(out, MARK), "w").write("vtnc offscreen probe\n")
for d in ["theme", "core", "services"]:
    os.makedirs(os.path.join(out, d), exist_ok=True)


def write(rel, text):
    path = os.path.realpath(os.path.join(out, rel))
    # stubs only ever land in the probe dir
    if not path.startswith(out + os.sep):
        sys.exit(f"refused: {path} is outside the probe dir")
    open(path, "w").write(text)


for name in ["kit", "components", "dwidgets", "iwidgets"]:
    link = os.path.join(out, name)
    if os.path.islink(link):
        os.unlink(link)
    if not os.path.exists(link):
        os.symlink(os.path.join(VTNC, name), link)

# Colors: every token of colorRoles.js, from the user's matugen json (else the fallback)
roles = open(os.path.join(VTNC, "theme/colorRoles.js")).read()
tokens = re.findall(r'\{ token: "(\w+)", role: "(\w+)"[^}]*fallback: "(#[0-9a-fA-F]{6})"', roles)
try:
    data = json.load(open(os.path.expanduser("~/.cache/vtnc/matugen.json")))
    colors = data.get("colors", data)
except Exception:
    colors = {}


def hexfor(role, fallback):
    v = colors.get(role)
    if isinstance(v, dict):
        v = v.get(mode, v.get("default"))
        if isinstance(v, dict):
            v = v.get("color")
    return v if isinstance(v, str) and v.startswith("#") else fallback


props = "\n".join(f'    readonly property color {t}: "{hexfor(r, fb)}"' for t, r, fb in tokens)
write("theme/Colors.qml", f'''pragma Singleton
import QtQuick
import Quickshell
// probe stub: the user's {mode} palette, transparency off
Singleton {{
{props}
    readonly property color green: "#b7d085"
    readonly property color red: "#ffb4ab"
    readonly property color yellow: "#dec56e"
    readonly property real wallLuminance: 0
    readonly property QtObject transparency: QtObject {{
        readonly property bool enabled: false
        readonly property real base: 0.85
        readonly property real layers: 0.4
    }}
    function layer(c: color, layer: int): color {{ return c; }}
    function lift(c: color, a: real, layer: int): color {{ return c; }}
    function luminance(c: color): real {{ return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b; }}
    function alpha(c: color, a: real): color {{ return Qt.rgba(c.r, c.g, c.b, a); }}
}}
''')

# the real Tokens and Icons (they only read Store.theme)
for f in ["Tokens.qml", "Icons.qml"]:
    write(os.path.join("theme", f), open(os.path.join(VTNC, "theme", f)).read())

# Store: the theme the kit reads; `island` from PROBE_ISLAND (json, e.g. a widget's options); nothing saved
write("core/Store.qml", f'''pragma Singleton
import QtQuick
import Quickshell
// probe stub: the theme the kit reads; nothing is saved
Singleton {{
    readonly property QtObject theme: QtObject {{
        readonly property bool light: {"true" if mode == "light" else "false"}
        readonly property string font: ""
        readonly property string monoFont: "CaskaydiaCove NF"
        readonly property string card: "neutral"
        readonly property var scale: ({{ rounding: 1, spacing: 1, padding: 1, font: 1, anim: 1 }})
        readonly property var transparency: ({{ enabled: false, base: 0.85, layers: 0.4 }})
        readonly property var jelly: ({{ enabled: true, strength: 1, maxStretch: 5, stiffness: 260, damping: 14 }})
        readonly property QtObject anim: QtObject {{
            readonly property real overshoot: 1.2
            readonly property real contentOvershoot: 0.6
            readonly property bool pageScale: false
        }}
    }}
    property var island: JSON.parse(Quickshell.env("PROBE_ISLAND") || "{{}}")
    readonly property QtObject player: QtObject {{ readonly property string pinned: "" }}
}}
''')

write("services/MprisController.qml", '''pragma Singleton
import QtQuick
import Quickshell
// probe stub: a fake player (PROBE_ART = an image path, PROBE_PAUSED=1)
Singleton {
    property var activePlayer: ({ identity: "Spotify", trackTitle: "Nude", trackArtist: "Radiohead", trackArtUrl: Quickshell.env("PROBE_ART") || "", length: 255, position: 90, canSeek: true, isPlaying: true, positionChanged: function() {} })
    property bool isPlaying: Quickshell.env("PROBE_PAUSED") !== "1"
    property bool canTogglePlaying: true
    property bool canGoPrevious: true
    property bool canGoNext: true
    property var filteredPlayers: [activePlayer]
    property string pinned: ""
    function togglePlaying() {}
    function previous() {}
    function next() {}
    function pin(p) {}
}
''')
print("probe ready:", out, mode)
