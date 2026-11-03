#!/usr/bin/env python3
# Moves folders or files of the shell to new places (R2 C4, the layout move) and rewrites every reference to
# them in the QML and JS code:
#   - `import qs.a.b` (the module follows its folder: qs.core → qs.base.core);
#   - relative `import "…"`, `.import "…"` and `Qt.resolvedUrl("…")`: resolved from the file's old place,
#     mapped, and made relative to its new place.
# Text in comments and Markdown is left alone (step 11 rewrites the docs).
#
#   python3 -I tools/move.py [--dry-run] old=new [old=new …]      (paths relative to the shell)
#
# A move into an existing folder is refused for a folder (merge by moving its files one by one). `git mv` keeps
# the history; nothing is committed.
import os, re, subprocess, sys

VTNC = os.path.realpath(os.environ.get("VTNC") or os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SKIP = {"tools", ".git"}

args = [a for a in sys.argv[1:] if a != "--dry-run"]
dry = "--dry-run" in sys.argv
if not args:
    sys.exit("usage: move.py [--dry-run] old=new [old=new …]")
moves = []
for a in args:
    old, _, new = a.partition("=")
    old, new = old.strip("/"), new.strip("/")
    if not old or not new or not os.path.exists(os.path.join(VTNC, old)):
        sys.exit(f"bad move: {a}")
    if os.path.isdir(os.path.join(VTNC, old)) and os.path.exists(os.path.join(VTNC, new)):
        sys.exit(f"refused: {new} exists (move a folder's files one by one to merge)")
    moves.append((old, new))
# longest first, so a file moved on its own wins over its folder's move
moves.sort(key=lambda m: -len(m[0]))


def mapped(rel):
    # a path relative to the shell after the moves
    for old, new in moves:
        if rel == old or rel.startswith(old + "/"):
            return new + rel[len(old):]
    return rel


def mapped_module(mod):
    # qs.a.b → the module of the folder a/b after the moves
    return "qs." + mapped(mod[3:].replace(".", "/")).replace("/", ".")


files = []
for base, dirs, names in os.walk(VTNC):
    # only the root's tools/ and .git (apps/tools is an app)
    if base == VTNC:
        dirs[:] = [d for d in dirs if d not in SKIP]
    for n in names:
        if n.endswith((".qml", ".js")):
            files.append(os.path.relpath(os.path.join(base, n), VTNC))

# Files moved on their own out of a folder that stays (a split): their types now live in another module.
# moved_types[old folder] = {type name: new folder}
moved_types = {}
for old, new in moves:
    if os.path.isfile(os.path.join(VTNC, old)) and old.endswith(".qml"):
        moved_types.setdefault(os.path.dirname(old), {})[os.path.basename(old)[:-4]] = os.path.dirname(new)


def code_of(text):
    # the text without imports and comments, to look for type names
    text = re.sub(r"^\s*\.?import .*$", "", text, flags=re.M)
    return re.sub(r"//.*", "", text)


def split_imports(rel, src, out):
    """after a split, an import of the old folder also needs the new one when this file uses a moved type
    through it; a moved file that uses a sibling left behind needs the old folder"""
    if not moved_types:
        return out
    body = code_of(src)
    here = os.path.dirname(rel)
    extra = []
    # imports of a split folder (qs.a.b or a relative folder), with their qualifier
    for m in re.finditer(r'^\s*import\s+(qs(?:\.\w+)+|"[^"]+")(?:\s+as\s+(\w+))?\s*$', src, re.M):
        target, alias = m.group(1), m.group(2)
        folder = target[3:].replace(".", "/") if target.startswith("qs.") else os.path.normpath(os.path.join(here, target.strip('"')))
        for name, new_folder in moved_types.get(folder, {}).items():
            used = re.search((r"\b" + alias + r"\." if alias else r"(?<![\w.])") + name + r"\b", body)
            if used:
                line = "import qs." + new_folder.replace("/", ".") + (" as " + alias if alias else "")
                if line not in extra:
                    extra.append(line)
    # a file that stays in a split folder used the moved types without an import (same folder)
    if rel not in [o for o, _ in moves] and here in moved_types:
        for name, new_folder in moved_types[here].items():
            if re.search(r"(?<![\w.])" + name + r"\b", body):
                line = "import qs." + new_folder.replace("/", ".")
                if line not in extra:
                    extra.append(line)
    # a moved file's siblings: the folder it left
    if rel in [o for o, _ in moves] and os.path.dirname(rel) in moved_types:
        left = os.path.dirname(rel)
        for n in os.listdir(os.path.join(VTNC, left)):
            name = n[:-4]
            if n.endswith(".qml") and name not in moved_types[left] and re.search(r"(?<![\w.])" + name + r"\b", body):
                line = "import qs." + mapped(left).replace("/", ".")
                if line not in extra:
                    extra.append(line)
    if not extra:
        return out
    lines = out.split("\n")
    last = max(i for i, l in enumerate(lines) if re.match(r"\s*\.?import ", l))
    lines[last + 1:last + 1] = [l for l in extra if l not in lines]
    return "\n".join(lines)


REL = re.compile(r'''^(\s*\.?import\s+")([^"]+)(")|(Qt\.resolvedUrl\(")([^"]+)("\))''', re.M)
QS = re.compile(r"^(\s*import\s+)(qs(?:\.[A-Za-z_]\w*)+)", re.M)
changed = {}
for rel in files:
    src = open(os.path.join(VTNC, rel), encoding="utf-8").read()
    old_dir = os.path.dirname(rel)
    new_dir = os.path.dirname(mapped(rel))

    def fix_rel(m):
        pre, path, post = (m.group(1), m.group(2), m.group(3)) if m.group(1) else (m.group(4), m.group(5), m.group(6))
        if "://" in path or path.startswith("/"):
            return m.group(0)
        target = os.path.normpath(os.path.join(old_dir, path))
        if target.startswith(".."):
            return m.group(0)
        new_target = mapped(target)
        r = os.path.relpath(new_target, new_dir or ".")
        if path.startswith("./") and not r.startswith("."):
            r = "./" + r
        return pre + r + post

    out = REL.sub(fix_rel, src)
    out = QS.sub(lambda m: m.group(1) + mapped_module(m.group(2)), out)
    out = split_imports(rel, src, out)
    if out != src:
        changed[rel] = out

print(f"{len(moves)} moves, {len(changed)} files rewritten")
if dry:
    for rel in sorted(changed):
        print("  " + rel + (" → " + mapped(rel) if mapped(rel) != rel else ""))
    sys.exit(0)

# the outer targets first (dashboard before dashboard/widgets: a folder moved into a target that already
# exists would land inside it)
for old, new in sorted(moves, key=lambda m: (m[1].count("/"), len(m[1]))):
    if os.path.isdir(os.path.join(VTNC, old)) and os.path.exists(os.path.join(VTNC, new)):
        sys.exit(f"refused at run time: {new} exists before {old} moves there")
    parent = os.path.dirname(os.path.join(VTNC, new))
    os.makedirs(parent, exist_ok=True)
    subprocess.run(["git", "-C", VTNC, "mv", old, new], check=True)
for rel, text in changed.items():
    with open(os.path.join(VTNC, mapped(rel)), "w", encoding="utf-8") as f:
        f.write(text)
print("done")
