#!/usr/bin/env python3
"""Aligns DEMO_SCREEN markers (logcat) to screencap frames and names them.

Usage: align_demo_screens.py <logcat.txt> <shots_dir> <out_dir>
Device clock is synced to the host on GitHub Actions; each named screenshot
is the first frame captured at/after its marker (small clock drift tolerated).
"""
import os
import re
import shutil
import sys
from datetime import datetime, timezone

log_path, shots_dir, out_dir = sys.argv[1:4]
os.makedirs(out_dir, exist_ok=True)

marker_pat = re.compile(
    r"(\d\d)-(\d\d)\s+(\d\d):(\d\d):(\d\d)\.\d+.*DEMO_SCREEN:\s*(\S+)")

# markers in chronological order: (epoch, name)
markers = []
current_year = datetime.now(timezone.utc).year
for line in open(log_path, encoding="utf-8", errors="replace"):
    m = marker_pat.search(line)
    if not m:
        continue
    month, day, hh, mm, ss, name = m.groups()
    try:
        dt = datetime(current_year, int(month), int(day),
                      int(hh), int(mm), int(ss), tzinfo=timezone.utc)
    except ValueError:
        continue
    markers.append((dt.timestamp(), name))

# keep the first occurrence of each marker name
seen = {}
for epoch, name in markers:
    if name not in seen:
        seen[name] = epoch
markers = sorted(seen.items(), key=lambda kv: kv[1])

# frames sorted by epoch
frames = []
for f in sorted(os.listdir(shots_dir)):
    if f.startswith("f_") and f.endswith(".png"):
        try:
            frames.append((float(f[2:-4]), f))
        except ValueError:
            continue
frames.sort()

print(f"markers: {len(markers)} | frames: {len(frames)}")

missing = []
for name, epoch in markers:
    # first frame at/after the marker (>= epoch - 2s), nearest otherwise
    after = [(ts, f) for ts, f in frames if ts >= epoch - 2.0]
    if after:
        best = min(after, key=lambda tf: abs(tf[0] - epoch))
    elif frames:
        best = min(frames, key=lambda tf: abs(tf[0] - epoch))
    else:
        missing.append(name)
        continue
    shutil.copyfile(os.path.join(shots_dir, best[1]),
                    os.path.join(out_dir, f"{name}.png"))
    print(f"{name}.png <- {best[1]} (delta {best[0]-epoch:+.1f}s)")

if missing:
    print("MISSING:", ", ".join(missing))
print("alignment done")
