#!/usr/bin/env python3
# The shell's check, run before every R2 commit (from the dev worktree, on the live shell at $VTNC):
#
#   1. tests     every tests/*.test.js with node
#   2. patterns  forbidden code (PATTERNS below): "fail" ones fail the check, "warn" ones only report
#   3. layers    the layer lint (tools/layers.py); reports only until R2 C4 (--strict-layers fails on it)
#   4. live      reloads the running shell (`qs -c <config> ipc call shell reload`) and reads the log lines
#                after it: a new ERROR, a "WARN scene" line, a binding loop or a "caused by" fails, unless
#                tools/known-log.txt lists it (each entry says which step removes it)
#
#   tools/check [--no-live] [--restart] [--strict-layers]
#
# --restart kills and restarts the shell instead of reloading: needed after a new enum value, shader or
# singleton member, which a reload keeps stale (the old value logs "Unable to assign [undefined]").
# Exit 0 = pass.
import glob, os, re, subprocess, sys, time

# the shell the tools sit in (the dev worktree), unless VTNC names another
VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
# its Quickshell config name: ~/.config/quickshell/<name> (vtnc-dev for the dev worktree)
CONFIG = os.environ.get("QS_CONFIG") or os.path.basename(VTNC)
TOOLS = os.path.dirname(os.path.abspath(__file__))
ANSI = re.compile(r"\x1b\[[0-9;]*m")

# (regex, level, why)
PATTERNS = [
    (r"\|\|=|&&=|\?\?=", "fail", "logical assignment: write a = a || b"),
    (r"Object\.fromEntries", "fail", "Object.fromEntries is missing in Quickshell's JS"),
    (r"\bqs\.compat\b", "warn", "compat/ is deleted in R2 C3"),
    # once per-island config lands (R2 C9): (r"\bStore\.island\.", "fail", "read the island's cfg"),
]

failed = []


def head(name):
    print(f"\n== {name}")


def tests():
    head("tests")
    files = sorted(f for f in glob.glob(os.path.join(VTNC, "**/tests/*.test.js"), recursive=True))
    passed = 0
    for f in files:
        r = subprocess.run(["node", f], capture_output=True, text=True)
        m = re.search(r"(\d+) passed, (\d+) failed", r.stdout)
        passed += int(m.group(1)) if m else 0
        if r.returncode or not m:
            failed.append("tests")
            print(f"FAIL {os.path.relpath(f, VTNC)}\n{r.stdout}{r.stderr}")
    print(f"{passed} passed in {len(files)} files")


def patterns():
    head("patterns")
    hits = 0
    for d, dirs, names in os.walk(VTNC):
        dirs[:] = [x for x in dirs if not x.startswith(".") and x not in ("tests", "tools")]
        for n in names:
            if not n.endswith((".qml", ".js")):
                continue
            path = os.path.join(d, n)
            for no, line in enumerate(open(path, encoding="utf-8"), 1):
                for rx, level, why in PATTERNS:
                    if re.search(rx, line):
                        hits += 1
                        print(f"{level.upper()} {os.path.relpath(path, VTNC)}:{no}  {why}")
                        if level == "fail" and "patterns" not in failed:
                            failed.append("patterns")
    print(f"{hits} hits")


def layers(strict):
    head("layers")
    r = subprocess.run([sys.executable, "-I", os.path.join(TOOLS, "layers.py")] + (["--strict"] if strict else []),
                       env=dict(os.environ, VTNC=VTNC))
    if r.returncode:
        failed.append("layers")


def log_lines():
    r = subprocess.run(["qs", "log", "-c", CONFIG], capture_output=True, text=True)
    return [ANSI.sub("", l) for l in (r.stdout + r.stderr).splitlines()]


def known():
    out = []
    for l in open(os.path.join(TOOLS, "known-log.txt"), encoding="utf-8"):
        l = l.strip()
        if l and not l.startswith("#"):
            out.append(re.compile(l))
    return out


def live(restart):
    head("live (restart)" if restart else "live (reload)")
    if restart:
        subprocess.run(["qs", "kill", "-c", CONFIG], capture_output=True)
        time.sleep(1)
        subprocess.run(["qs", "-c", CONFIG, "-d"], capture_output=True)
        start = 0
    else:
        start = len(log_lines())
        r = subprocess.run(["qs", "-c", CONFIG, "ipc", "call", "shell", "reload"], capture_output=True, text=True)
        if r.returncode:
            failed.append("live")
            print(f"FAIL no running `qs -c {CONFIG}` to reload (start it, or QS_CONFIG=vtnc): {r.stderr.strip()}")
            return
    # wait for the load's result, then a moment for the warnings that come after it
    new = []
    for _ in range(40):
        time.sleep(0.5)
        new = log_lines()[start:]
        if any("Configuration Loaded" in l or "Failed to load configuration" in l for l in new):
            break
    time.sleep(4)
    new = log_lines()[start:]
    rules = known()
    bad, seen = {}, {}
    for l in new:
        if not re.search(r"ERROR|WARN scene|binding loop|caused by", l):
            continue
        key = re.sub(r"0x[0-9a-f]+", "0x…", l.strip())
        if any(rx.search(l) for rx in rules):
            seen[key] = seen.get(key, 0) + 1
        else:
            bad[key] = bad.get(key, 0) + 1
    for l, n in seen.items():
        print(f"known ×{n}  {l}")
    for l, n in bad.items():
        print(f"NEW   ×{n}  {l}")
    if not any("Configuration Loaded" in l for l in new):
        bad["no Configuration Loaded"] = 1
        print("FAIL the shell didn't load")
    if bad:
        failed.append("live")
        if any("Unable to assign [undefined]" in l for l in bad):
            print("(a new enum / singleton member? run with --restart)")
    print(f"{len(new)} new log lines, {sum(seen.values())} known, {sum(bad.values())} new")


def main():
    sys.stdout.reconfigure(line_buffering=True)
    print(f"vtnc check: {VTNC} (qs -c {CONFIG})")
    tests()
    patterns()
    layers("--strict-layers" in sys.argv)
    if "--no-live" not in sys.argv:
        live("--restart" in sys.argv)
    print("\n" + (f"FAILED: {', '.join(failed)}" if failed else "PASSED"))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
