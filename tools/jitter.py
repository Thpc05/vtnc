#!/usr/bin/env python3
# The jitter meter: tracks the island's body and its text frame by frame in a screen recording, so tremor
# and stutter become numbers (R2: the island tremor of 2026-10-28 was measured this way).
#
#   python3 -I tools/jitter.py <video> [--crop X,Y,W,H] [--text X,Y,W,H] [--thr 90] [--light]
#                              [--text-thr 180] [--from S] [--to S] [-v]
#
# Record a region around the island (or pass --crop). The body is the pixels darker than --thr; --text is a
# box (in the cropped picture) around a text that stays the same through the clip, e.g. the clock, tracked
# by its pixels brighter than --text-thr. --light inverts the picture first (a light body, dark text).
# Edges are found to a fraction of a pixel on the body's middle row and centre column.
#
# Prints a summary (-v: one line per frame):
#   repeated   frames identical to the one before; in motion they are frames the shell didn't draw (stutter)
#   rest       the stretches where the body stays still: how much its edges and the text still move
#   tremor     (with --text) while the body moves: the text against the body's centre; a "reversal" is the
#              text stepping back and forth by more than 0.25 px (the 2026-10-28 tremor: whole-pixel ones)
# Needs ffmpeg and numpy.
import json, subprocess, sys, warnings

import numpy as np

# a stretch where the text box is empty is fine (nan)
warnings.filterwarnings("ignore", category=RuntimeWarning)


def arg(name, default=None):
    a = sys.argv
    return a[a.index(name) + 1] if name in a and a.index(name) + 1 < len(a) else default


def probe(video):
    r = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                        "stream=width,height,avg_frame_rate", "-of", "json", video], capture_output=True, text=True)
    s = json.loads(r.stdout)["streams"][0]
    n, d = s["avg_frame_rate"].split("/")
    return s["width"], s["height"], float(n) / float(d or 1)


def frames(video, crop, w, h, start, end):
    vf = ["-vf", "crop={2}:{3}:{0}:{1}".format(*crop)] if crop else []
    span = (["-ss", start] if start else []) + (["-to", end] if end else [])
    p = subprocess.Popen(["ffmpeg", "-v", "error"] + span + ["-i", video] + vf +
                         ["-f", "rawvideo", "-pix_fmt", "gray", "-"], stdout=subprocess.PIPE)
    while True:
        b = p.stdout.read(w * h)
        if len(b) < w * h:
            return
        yield np.frombuffer(b, np.uint8).reshape(h, w).astype(float)


def cross(v, outside, inside, thr):
    """Where the line v crosses thr between pixel `outside` and its neighbour `inside`, to a fraction."""
    a, b = v[outside], v[inside]
    return outside + (a - thr) / (a - b) * (inside - outside) if a != b else inside


def measure(f, thr, light, text_thr, box):
    g = 255 - f if light else f
    t = 255 - thr if light else thr
    body = g < t
    rows = body.sum(1)
    if rows.max() < 4:
        return None
    # the middle of the rows that are (nearly) as wide as the body: stable while it grows
    full = np.where(rows >= 0.9 * rows.max())[0]
    y = int(full[len(full) // 2])
    xs = np.where(body[y])[0]
    L = cross(g[y], xs[0] - 1, xs[0], t) if xs[0] > 0 else 0.0
    R = cross(g[y], xs[-1] + 1, xs[-1], t) if xs[-1] < f.shape[1] - 1 else f.shape[1] - 1.0
    x = int(round((L + R) / 2))
    ys = np.where(body[:, x])[0]
    T = cross(g[:, x], ys[0] - 1, ys[0], t) if ys[0] > 0 else 0.0
    B = cross(g[:, x], ys[-1] + 1, ys[-1], t) if ys[-1] < f.shape[0] - 1 else f.shape[0] - 1.0
    # the text: its bright marks inside the box, weighted by brightness
    tx = ty = float("nan")
    if box:
        x0, y0, x1, y1 = box[0], box[1], box[0] + box[2], box[1] + box[3]
        wgt = np.clip(g[y0:y1, x0:x1] - text_thr, 0, None)
        if wgt.sum() > 0:
            tx = (wgt.sum(0) * np.arange(x0, x1)).sum() / wgt.sum()
            ty = (wgt.sum(1) * np.arange(y0, y1)).sum() / wgt.sum()
    return L, R, T, B, tx, ty


def main():
    if len(sys.argv) < 2 or sys.argv[1].startswith("-"):
        sys.exit("usage: jitter.py <video> [--crop X,Y,W,H] [--thr N] [--light] [--text-thr N] [--from S] [--to S] [-v]")
    video = sys.argv[1]
    w, h, fps = probe(video)
    crop = [int(v) for v in arg("--crop").split(",")] if arg("--crop") else None
    if crop:
        w, h = crop[2], crop[3]
    thr, text_thr, light = float(arg("--thr", 90)), float(arg("--text-thr", 180)), "--light" in sys.argv
    verbose = "-v" in sys.argv
    box = [int(v) for v in arg("--text").split(",")] if arg("--text") else None
    start = float(arg("--from", 0))

    rows, prev = [], None
    for i, f in enumerate(frames(video, crop, w, h, arg("--from"), arg("--to"))):
        m = measure(f, thr, light, text_thr, box)
        rep = prev is not None and np.abs(f - prev).max() < 3
        prev = f
        if m:
            rows.append((start + i / fps, rep) + m)
    if not rows:
        sys.exit("no body found (try --crop, --thr or --light)")
    a = np.array([r[2:] for r in rows])  # L R T B tx ty
    t = np.array([r[0] for r in rows])
    rep = np.array([r[1] for r in rows])
    width, centre = a[:, 1] - a[:, 0], (a[:, 0] + a[:, 1]) / 2
    rel = a[:, 4] - centre
    moving = np.zeros(len(a), bool)
    d = np.abs(np.diff(a[:, :4], axis=0)).max(1)
    moving[1:] = d > 0.05
    # a repeated frame between moving ones is a frame the shell didn't draw
    stutter = rep & np.convolve(moving, [1, 0, 1], "same").astype(bool)

    if verbose:
        for k in range(len(a)):
            L, R, T, B, tx, ty = a[k]
            print(f"{t[k]:7.3f} {'M' if moving[k] else ' '}{'r' if rep[k] else ' '} L{L:7.2f} R{R:7.2f} T{T:6.2f} "
                  f"B{B:6.2f} w{width[k]:7.2f} c{centre[k]:7.2f} text{tx:7.2f},{ty:6.2f} rel{rel[k]:+6.2f}")
        print()

    print(f"{video}: {len(a)} frames at {fps:g} fps ({t[-1] - t[0]:.2f} s), crop {crop or 'none'}")
    print(f"repeated  {int(rep.sum())} frames, {int(stutter.sum())} of them in motion (stutter)")
    # rest: runs of ≥ 10 still frames
    runs, k = [], 0
    while k < len(a):
        j = k
        while j + 1 < len(a) and not moving[j + 1]:
            j += 1
        if j - k + 1 >= 10:
            runs.append((k, j))
        k = j + 1
    for k, j in runs:
        s = a[k:j + 1]
        span = np.ptp(s[:, :4], axis=0)
        text = f", text {np.nanmax(s[:, 4]) - np.nanmin(s[:, 4]):.2f} px" if box else ""
        print(f"rest      {t[k]:.2f}–{t[j]:.2f} s: edges move L{span[0]:.2f} R{span[1]:.2f} T{span[2]:.2f} "
              f"B{span[3]:.2f} px{text}")
    # tremor: the text against the body's centre while moving
    idx = np.where(moving & ~np.isnan(rel))[0]
    if not box:
        print(f"tremor    {int(moving.sum())} moving frames; pass --text X,Y,W,H to track a text against the body")
    elif len(idx) > 2:
        dr = np.diff(rel[idx])
        big = dr[np.abs(dr) > 0.25]
        rev = int((np.sign(big[1:]) != np.sign(big[:-1])).sum()) if len(big) > 1 else 0
        print(f"tremor    {len(idx)} moving frames: text vs centre spans {np.ptp(rel[idx]):.2f} px, "
              f"steps > 0.25 px: {len(big)}, reversals: {rev}, biggest step {np.abs(dr).max():.2f} px")
    else:
        print("tremor    no motion found")


if __name__ == "__main__":
    main()
