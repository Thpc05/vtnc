#!/usr/bin/env python3
# Adds the island bits to a probe made by mkprobe.py, so galleries can host real Iwidgets in an
# IwidgetFrame (island/widgets/IwidgetFrame.qml):
#  - island/widgets/: a real folder with a link to each Iwidget, catalog.js and IwidgetFrame, and the real
#    registry (WidgetRegistry.qml) trimmed to the Iwidgets asked for (default: battery, tray,
#    volume; others may need more service stubs);
#  - base/core/Runtime.qml, base/services/Battery.qml (PROBE_BATT="<percent>[,charging]"), base/services/Audio.qml.
# Store.island comes from PROBE_ISLAND (see mkprobe.py). Nothing is written in the shell.
#
#   python3 -I tools/probe/mkisland.py <probe dir> [widget id ...]
import os, re, sys

# the shell the tools sit in (the dev worktree), unless VTNC names another
VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MARK = ".vtnc-probe"

if len(sys.argv) < 2:
    sys.exit("usage: mkisland.py <probe dir> [widget id ...]")
out = os.path.realpath(sys.argv[1])
wanted = sys.argv[2:] or ["battery", "tray", "volume"]

# only a probe made by mkprobe.py, never the shell itself
if out == VTNC or out.startswith(VTNC + os.sep):
    sys.exit(f"refused: {out} is inside the shell's code ({VTNC})")
if not os.path.exists(os.path.join(out, MARK)):
    sys.exit(f"refused: {out} is not a probe dir (run mkprobe.py first)")


def write(rel, text):
    path = os.path.realpath(os.path.join(out, rel))
    if not path.startswith(out + os.sep):
        sys.exit(f"refused: {path} is outside the probe dir")
    open(path, "w").write(text)


# the real registry, keeping only the wanted Iwidgets (imports, the components map and their Components)
# island/widgets: a real folder (the trimmed registry lives in it) with the rest linked
widgets_dir = os.path.join(out, "island", "widgets")
if os.path.islink(widgets_dir):
    os.unlink(widgets_dir)
os.makedirs(widgets_dir, exist_ok=True)
for n in os.listdir(os.path.join(VTNC, "island/widgets")):
    if n == "WidgetRegistry.qml":
        continue
    link = os.path.join(widgets_dir, n)
    if not os.path.lexists(link):
        os.symlink(os.path.join(VTNC, "island/widgets", n), link)
reg = open(os.path.join(VTNC, "island/widgets/WidgetRegistry.qml")).read()
keep = "|".join(map(re.escape, wanted))
reg = re.sub(r'import qs\.island\.widgets\.(?!(?:%s) as)\w+ as \w+\n' % keep, '', reg)
# (the map's lines only: `id: xComponent` lines of the Components below are left for the next step)
reg = re.sub(r'\n\s*(?!(?:%s|id):)\w+: \w+Component,?' % keep, '', reg)
reg = re.sub(r'    Component \{\n        id: (?!(?:%s)Component\b)\w+\n        [\w.]+ \{\}\n    \}\n' % keep, '', reg)
write("island/widgets/WidgetRegistry.qml", reg)

write("base/core/Runtime.qml", '''pragma Singleton
import QtQuick
import Quickshell
Singleton { property string activeScreen: "" }
''')
write("base/services/Battery.qml", '''pragma Singleton
import QtQuick
import Quickshell
// probe stub: PROBE_BATT=<percent>[,charging]
Singleton {
    readonly property var spec: (Quickshell.env("PROBE_BATT") || "34").split(",")
    property bool available: true
    property real percentage: Number(spec[0])
    property bool charging: spec[1] === "charging"
    property bool pluggedIn: charging
    property bool low: !pluggedIn && percentage <= 20
}
''')
write("base/services/Audio.qml", '''pragma Singleton
import QtQuick
import Quickshell
// probe stub: 42 %, not muted
Singleton {
    property real value: 0.42
    property var sink: ({ audio: { muted: false } })
    function setVolume(v) {}
    function toggleMute() {}
    function volumeIcon(v, muted) { return muted ? "volume_off" : "volume_up"; }
}
''')
print("island probe ready:", out, "with", ", ".join(wanted))
