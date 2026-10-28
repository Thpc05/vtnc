#!/usr/bin/env python3
# The layer lint: every `import qs.X` and relative import of the shell's QML / JS must go down the layers
# of the folder layout "by surface" (R2, the vault's definitions/folder layout):
#
#   base/core → base/theme → base/kit → base/services → apps/common → features → shell
#
# a file may import its own layer or a lower one, and a feature (island, dashboard, settings, each app) may
# not import another feature. Today's folders (before the R2 move) are mapped onto the same layers, so the
# first runs list the backlog of R2 phase C steps 4–5.
#
#   python3 -I tools/layers.py [--strict] [-v]        (VTNC = the shell, default the one around tools/)
#
# Prints the violations grouped by "from area → to area"; -v lists every import line. --strict exits 1
# when there is any violation or unmapped file (tools/check uses it once the move is done).
import os, re, sys

# the shell the tools sit in (the dev worktree), unless VTNC names another
VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SKIP = {".git", ".claude", "assets", "defaults", "scripts", "tests", "tools"}

LAYERS = ["core", "theme", "kit", "services", "common", "feature", "shell"]

# path prefix → (layer, feature); the longest prefix wins. "apps/*" = each app is its own feature.
MAP = {
    # layout B
    "base/core": ("core", None),
    "base/theme": ("theme", None),
    "base/kit": ("kit", None),
    "base/services": ("services", None),
    "apps/common": ("common", None),
    "island": ("feature", "island"),
    "dashboard": ("feature", "dashboard"),
    "settings": ("feature", "settings"),
    "apps/*": ("feature", None),
    # the apps' root (AppRegistry: every app; R2 C5 generates it from apps/<id>/meta.js)
    "apps": ("shell", None),
    "shell": ("shell", None),
    "shell.qml": ("shell", None),
    # today's folders (drop them after the move, R2 C4)
    "core": ("core", None),
    "theme": ("theme", None),
    "kit": ("kit", None),
    "components": ("kit", None),
    "services": ("services", None),
    "compat": ("services", None),
    "iwidgets": ("feature", "island"),
    "dwidgets": ("feature", "dashboard"),
    "apps/dashboard": ("feature", "dashboard"),
    "apps/settings": ("feature", "settings"),
    "frame": ("shell", None),
}

QS = re.compile(r'^\s*\.?import\s+qs\.([\w.]+)')
REL = re.compile(r'^\s*\.?import\s+"([^"]+)"')


def area(rel):
    """(layer, feature, area name) of a path relative to the shell, or None when unmapped."""
    parts = rel.split("/")
    best = None
    for key, (layer, feature) in MAP.items():
        k = key.split("/")
        if k[-1] == "*":
            name = "/".join(parts[: len(k)])
            # only a folder is an app (apps/AppRegistry.qml is the apps' root)
            if len(parts) >= len(k) and parts[: len(k) - 1] == k[:-1] and os.path.isdir(os.path.join(VTNC, name)):
                # a wildcard loses to an exact key of the same length (apps/common, apps/settings)
                hit = (len(k) - 0.5, layer, name, name)
            else:
                continue
        elif parts[: len(k)] == k:
            hit = (len(k), layer, feature, key)
        else:
            continue
        if best is None or hit[0] > best[0]:
            best = hit
    return best and best[1:]


def files():
    for d, dirs, names in os.walk(VTNC):
        dirs[:] = sorted(x for x in dirs if x not in SKIP and not x.startswith("."))
        for n in sorted(names):
            if n.endswith((".qml", ".js")):
                yield os.path.relpath(os.path.join(d, n), VTNC)


def imports(rel):
    here = os.path.dirname(os.path.join(VTNC, rel))
    for no, line in enumerate(open(os.path.join(VTNC, rel), encoding="utf-8"), 1):
        m = QS.match(line)
        if m:
            yield no, "qs." + m.group(1), m.group(1).replace(".", "/")
            continue
        m = REL.match(line)
        if m:
            target = os.path.normpath(os.path.join(here, m.group(1)))
            yield no, '"' + m.group(1) + '"', os.path.relpath(target, VTNC)


def main():
    strict = "--strict" in sys.argv
    verbose = "-v" in sys.argv
    groups, unmapped, count = {}, set(), 0
    for rel in files():
        src = area(rel)
        if not src:
            unmapped.add(rel)
            continue
        for no, text, target in imports(rel):
            if target.startswith(".."):
                continue
            count += 1
            dst = area(target)
            if not dst:
                unmapped.add(target)
                continue
            (sl, sf, sa), (dl, df, da) = src, dst
            if LAYERS.index(dl) > LAYERS.index(sl):
                why = f"{sl} imports {dl}"
            elif sl == dl == "feature" and sf != df:
                why = "a feature imports another feature"
            else:
                continue
            groups.setdefault((sa, da, why), []).append(f"{rel}:{no}  {text}")

    total = sum(len(v) for v in groups.values())
    print(f"layers: {count} imports, {total} violations in {len(groups)} pairs, {len(unmapped)} unmapped")
    for (sa, da, why), lines in sorted(groups.items(), key=lambda g: (-len(g[1]), g[0])):
        files_ = sorted({l.split(":")[0] for l in lines})
        print(f"  {sa} → {da}  ({why}): {len(lines)} imports in {len(files_)} files")
        for l in lines if verbose else files_[:3] + (["…"] if len(files_) > 3 else []):
            print(f"      {l}")
    for u in sorted(unmapped):
        print(f"  unmapped: {u}")
    return 1 if strict and (total or unmapped) else 0


if __name__ == "__main__":
    sys.exit(main())
