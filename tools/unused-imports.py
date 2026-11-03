#!/usr/bin/env python3
# Lists the QML imports a file doesn't use: `import qs.a.b` / a relative folder when no name that folder
# exports (its .qml files) appears in the file, an aliased import when its alias never does. Conservative:
# any matching word counts as a use.
#
#   python3 -I tools/unused-imports.py [--fix]
import os, re, sys

VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
fix = "--fix" in sys.argv


def exports(folder):
    if not os.path.isdir(folder):
        return None
    return {n[:-4] for n in os.listdir(folder) if n.endswith(".qml")}


hits = 0
for base, dirs, files in os.walk(VTNC):
    # only the root's tools/ and .git (apps/tools is an app)
    if base == VTNC:
        dirs[:] = [d for d in dirs if d not in ("tools", ".git")]
    for f in files:
        if not f.endswith(".qml"):
            continue
        path = os.path.join(base, f)
        src = open(path, encoding="utf-8").read()
        lines = src.split("\n")
        body = re.sub(r"//.*", "", "\n".join(l for l in lines if not l.startswith("import ")))
        keep = []
        for l in lines:
            m = re.match(r'import (qs\.[\w.]+|"[^"]+")(?:\s+as\s+(\w+))?\s*$', l)
            unused = False
            if m:
                mod, alias = m.group(1), m.group(2)
                if alias:
                    unused = not re.search(r"\b" + alias + r"\.", body)
                else:
                    folder = os.path.join(VTNC, *mod[3:].split(".")) if mod.startswith("qs.") else os.path.normpath(os.path.join(base, mod.strip('"')))
                    names = None if mod.endswith('.js"') else exports(folder)
                    unused = bool(names) and not any(re.search(r"\b" + re.escape(n) + r"\b", body) for n in names)
            if unused:
                hits += 1
                print(os.path.relpath(path, VTNC) + ": " + l)
            else:
                keep.append(l)
        if fix and len(keep) != len(lines):
            open(path, "w", encoding="utf-8").write("\n".join(keep))
print(hits, "unused")
