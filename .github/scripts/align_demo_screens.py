#!/usr/bin/env python3
"""Aligns DEMO_SCREEN markers to screencap frames and names them.

Usage: align_demo_screens.py <shots_dir> <out_dir> [marker_files...]

Marker files: logcat.txt (device time `MM-DD HH:MM:SS.xxx`) and/or
flutter_test_log.txt (runner stdout with ISO-8601 UTC timestamps).
Each named screenshot is the first frame captured at/after its marker.
"""
import os
import re
import shutil
import sys
from datetime import datetime, timezone

shots_dir, out_dir = sys.argv[1], sys.argv[2]
marker_files = sys.argv[3:]
os.makedirs(out_dir, exist_ok=True)

logcat_pat = re.compile(
    r"(\d\d)-(\d\d)\s+(\d\d):(\d\d):(\d\d)\.\d+.*DEMO_SCREEN:\s*(\S+)")
iso_pat = re.compile(
    r"(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z?)\s.*DEMO_SCREEN:\s*(\S+)")
# new test marker format: DEMO_SCREEN|<device_epoch_ms>|<name>
epoch_pat = re.compile(r"DEMO_SCREEN\|(\d{13})\|(\S+)")

markers = []
current_year = datetime.now(timezone.utc).year

for path in marker_files:
    if not os.path.isfile(path):
        continue
    for line in open(path, encoding="utf-8", errors="replace"):
        m = epoch_pat.search(line)
        if m:
            markers.append((int(m.group(1)) / 1000.0, m.group(2)))
            continue
        m = logcat_pat.search(line)
        if m:
            month, day, hh, mm, ss, name = m.groups()
            try:
                dt = datetime(current_year, int(month), int(day),
                              int(hh), int(mm), int(ss), tzinfo=timezone.utc)
            except ValueError:
                continue
            markers.append((dt.timestamp(), name))
            continue
        m = iso_pat.search(line)
        if m:
            ts, name = m.groups()
            if ts.endswith("Z"):
                ts = ts[:-1] + "+00:00"
            try:
                dt = datetime.fromisoformat(ts)
            except ValueError:
                continue
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            markers.append((dt.timestamp(), name))

# keep the first occurrence of each marker name, chronological
seen = {}
for epoch, name in markers:
    if name not in seen:
        seen[name] = epoch
markers = sorted(seen.items(), key=lambda kv: kv[1])

frames = []
for f in sorted(os.listdir(shots_dir)):
    if f.startswith("f_") and f.endswith(".png"):
        try:
            frames.append((float(f[2:-4]), f))
        except ValueError:
            continue
frames.sort()

print(f"marker files: {marker_files}")
print(f"markers: {len(markers)} | frames: {len(frames)}")

missing = []
for name, epoch in markers:
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
