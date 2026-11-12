#!/usr/bin/env python3
# Brings pytest's XML report to the form ViD reads: a failure message that begins with `setup:` keeps it at its start,
# and each `covers: <row> <number>` line a test prints is shown on a line of its own.
#   finish_report.py <pytest's report> <the finished report>
import re
import sys
import xml.etree.ElementTree as ET

WRAPPED = re.compile(r'^(?:failed on setup with ")?(?:[\w.]+: )?(setup: .*?)"?$', re.DOTALL)
COVERS = re.compile(r"^covers: \S+ \d+$", re.MULTILINE)

tree = ET.parse(sys.argv[1])
for tag in ("failure", "error"):
    for broken in tree.iter(tag):
        found = WRAPPED.match(broken.get("message", ""))
        if found:
            broken.set("message", found.group(1))
for out in tree.iter("system-out"):
    for line in COVERS.findall(out.text or ""):
        print(line, flush=True)
tree.write(sys.argv[2], encoding="unicode")
