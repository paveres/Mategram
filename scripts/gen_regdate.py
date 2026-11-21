import csv
import statistics
import sys
from collections import defaultdict

src, out = sys.argv[1], sys.argv[2]
ALLOWED = {"obs", "month"}

by_id = defaultdict(list)
with open(src, newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        if row["kind"] not in ALLOWED:
            continue
        by_id[int(row["id"])].append(int(row["ts"]))

nodes = sorted((i, int(statistics.median(ts))) for i, ts in by_id.items())

blocks = [[i, t, 1] for i, t in nodes]
merged = []
for b in blocks:
    merged.append(b)
    while len(merged) >= 2 and merged[-2][1] / merged[-2][2] > merged[-1][1] / merged[-1][2]:
        last = merged.pop()
        prev = merged.pop()
        merged.append([last[0], prev[1] + last[1], prev[2] + last[2]])

mono = []
idx = 0
for i, t in nodes:
    mono.append((i, t))
fixed = []
pos = 0
for b in merged:
    count = b[2]
    value = b[1] // count
    for k in range(count):
        fixed.append((nodes[pos][0], value))
        pos += 1

ids = [i for i, _ in fixed]
times = [t for _, t in fixed]
assert ids == sorted(ids)
assert all(times[k] <= times[k + 1] for k in range(len(times) - 1))

with open(out, "w", encoding="utf-8", newline="\n") as o:
    o.write("import Foundation\n\n")
    o.write("enum MategramRegDateAnchors {\n")
    o.write("    static let ids: [Int64] = [\n")
    for k in range(0, len(ids), 8):
        o.write("        " + ", ".join(str(x) for x in ids[k:k + 8]) + ",\n")
    o.write("    ]\n\n")
    o.write("    static let times: [Int32] = [\n")
    for k in range(0, len(times), 8):
        o.write("        " + ", ".join(str(x) for x in times[k:k + 8]) + ",\n")
    o.write("    ]\n}\n")
print("nodes:", len(ids), "first:", ids[0], times[0], "last:", ids[-1], times[-1])
