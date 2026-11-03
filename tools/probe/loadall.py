#!/usr/bin/env python3
# Compiles every QML file of the shell offscreen, without creating anything, and reports the ones that don't
# load: a missing type, a property that doesn't exist, a broken import, a syntax error. It covers what the
# live check never builds (Dwidgets that are off, every panel, every Settings page). Nothing runs: no
# service, process or window is created, and the shell's files are only read (symlinks).
#
#   python3 -I tools/probe/loadall.py [path filter]
#
# Builds a config in PROBE_DIR/loadall (default $XDG_RUNTIME_DIR/vtnc-probe/loadall, refused inside the shell)
# with the shell's folders linked and a loader as its shell.qml, runs it with `qs -p` on the offscreen
# platform and reads its log. Exit 1 when a file fails. JS errors only show when the code runs: not here.
import os, re, selectors, subprocess, sys, time

VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ROOT = os.path.realpath(os.environ.get("PROBE_DIR") or os.path.join(os.environ.get("XDG_RUNTIME_DIR") or "/tmp", "vtnc-probe"))
OUT = os.path.join(ROOT, "loadall")
MARK = ".vtnc-probe"
SKIP_DIRS = {"tools", "defaults", "scripts", ".git", "tests"}

if OUT == VTNC or OUT.startswith(VTNC + os.sep):
    sys.exit(f"refused: {OUT} is inside the shell's code ({VTNC})")
if os.path.isdir(OUT) and os.listdir(OUT) and not os.path.exists(os.path.join(OUT, MARK)):
    sys.exit(f"refused: {OUT} is not empty and is not a probe dir (no {MARK})")
os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, MARK), "w").write("vtnc offscreen probe (loadall)\n")

# the shell's top folders, linked (read only); the loader is this config's own shell.qml
folders = sorted(d for d in os.listdir(VTNC) if os.path.isdir(os.path.join(VTNC, d)) and d not in SKIP_DIRS and not d.startswith("."))
for d in folders:
    link = os.path.join(OUT, d)
    if os.path.islink(link):
        os.unlink(link)
    if not os.path.exists(link):
        os.symlink(os.path.join(VTNC, d), link)

flt = sys.argv[1] if len(sys.argv) > 1 else ""
files = []
qml_dirs = set()
for d in folders:
    for base, dirs, names in os.walk(os.path.join(VTNC, d)):
        # the tests' folders hold no QML; any other folder counts (apps/tools is an app)
        dirs[:] = [x for x in dirs if x != "tests"]
        for n in names:
            if not n.endswith(".qml"):
                continue
            rel = os.path.relpath(os.path.join(base, n), VTNC)
            qml_dirs.add(os.path.dirname(rel))
            if flt and flt not in rel:
                continue
            # a singleton can't be created as a component; it compiles when something imports it
            head = open(os.path.join(base, n), encoding="utf-8").read(400)
            if re.search(r"^pragma Singleton", head, re.M):
                continue
            files.append(rel)
files.sort()

# every folder with QML files as a module: Quickshell registers a qs.* module when an import names it
# (a folder with no QML of its own, like base/, is no module)
modules = sorted(d.replace(os.sep, ".") for d in qml_dirs if d != "")
imports = "\n".join(f"import qs.{m} as M{i}" for i, m in enumerate(modules) if re.fullmatch(r"[a-z][\w.]*", m))

with open(os.path.join(OUT, "files.txt"), "w") as f:
    f.write("\n".join(files))
with open(os.path.join(OUT, "shell.qml"), "w") as f:
    f.write('''import QtQuick
import Quickshell
import Quickshell.Io
''' + imports + '''

// loadall: compiles each file of files.txt (Qt.createComponent, nothing created) and logs the failures
Scope {
    FileView {
        id: list
        path: Quickshell.shellDir + "/files.txt"
        blockLoading: true
    }
    Component.onCompleted: {
        const files = list.text().split("\\n").filter(f => f !== "");
        let bad = 0;
        for (const f of files) {
            const c = Qt.createComponent(Quickshell.shellDir + "/" + f, Component.PreferSynchronous);
            if (c.status === Component.Error) {
                bad++;
                console.log("LOADALL FAIL " + f + "\\n" + c.errorString());
            }
        }
        console.log("LOADALL DONE " + files.length + " " + bad);
        Qt.quit();
    }
}
''')

env = dict(os.environ, QT_QPA_PLATFORM="offscreen")
# qs doesn't exit on Qt.quit() here: read until the loader's last line (or a failed load), then stop it
proc = subprocess.Popen(["timeout", "120", "qs", "-p", os.path.join(OUT, "shell.qml")], cwd=OUT, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, text=True, env=env)
out = []
sel = selectors.DefaultSelector()
sel.register(proc.stdout, selectors.EVENT_READ)
deadline = time.time() + 120
while time.time() < deadline:
    if not sel.select(timeout=deadline - time.time()):
        break
    line = proc.stdout.readline()
    if not line:
        break
    out.append(line)
    if "LOADALL DONE" in line:
        break
    # a failed load prints its "caused by" chain right after: read it for a second more
    if "Failed to load configuration" in line:
        deadline = min(deadline, time.time() + 1)
proc.kill()
proc.wait()
log = re.sub(r"\x1b\[[0-9;]*m", "", "".join(out))
done = re.search(r"LOADALL DONE (\d+) (\d+)", log)
fails = re.findall(r"LOADALL FAIL (\S+)\n((?:.*\n)*?)(?=\s*(?:DEBUG|INFO|WARN|ERROR|$))", log)
# a window needs Wayland, which the offscreen platform hasn't: those files can't be checked here
skipped = [f for f, why in fails if "No PanelWindow backend loaded" in why]
fails = [(f, why) for f, why in fails if f not in skipped]
for f, why in fails:
    lines = [l.strip() for l in why.strip().splitlines() if l.strip()]
    print(f"FAIL {f}")
    for l in lines[:6]:
        print(f"     {l.replace('file://' + OUT + '/', '')}")
if not done:
    # a broken file a singleton depends on stops the loader itself: the chain's last "caused by" is the cause
    chain = [l.strip() for l in log.splitlines() if "caused by" in l]
    if chain:
        print("FAIL the loader itself didn't load; the cause (fix it and run again for the rest):\n     "
              + re.sub(r"^.*caused by ", "", chain[-1]))
    else:
        print("loadall: the loader didn't finish:\n" + "\n".join(log.splitlines()[-15:]))
    sys.exit(1)
print(f"loadall: {done.group(1)} files compiled, {len(fails)} failed, {len(skipped)} skipped (windows need Wayland: "
      + ", ".join(skipped) + ")")
sys.exit(1 if fails else 0)
