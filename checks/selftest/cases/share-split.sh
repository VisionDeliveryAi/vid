#!/bin/sh
# Purpose: selftest case — every file of a share under GitHub's 100 MB push limit (0.26.10.28.7, stage 3 R2). The default limit,
# as the manifest states it, is under 100 MiB. With the limit lowered for the case (VID_SHARE_SPLIT_BYTES=100000, as export.sh's
# case lowers its own: a text file large enough to stay over 95 MiB after gzip would take minutes to make and redact), a logs file
# of 250,000 bytes that is not gzipped is cut into <file>.part-000 … each at most the limit, the whole file gone, the parts
# rejoining to it byte for byte, and the split listed in the manifest and the summary; a small file is not cut. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-split: $*" >&2; cat "$T/out" >&2 2>/dev/null || true; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
P=$T/proj; mkdir -p "$P/checks" "$P/.vid" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md
sh checks/share.sh build --run 2026-11-d > "$T/out" 2>&1 || fail 'the build failed'
L=$(sed -n 's/.*"split_limit_bytes": \([0-9]*\).*/\1/p' .vid/shares/2026-11-d/MANIFEST.json); [ -n "$L" ] && [ "$L" -lt 104857600 ] || fail "the default limit is not under 100 MiB: $L"
awk 'BEGIN { for (i = 0; i < 5000; i++) printf "%049d\n", i }' > "$T/dev/big.txt"
[ "$(wc -c < "$T/dev/big.txt" | tr -d ' ')" = 250000 ] || fail 'the fixture is not 250000 bytes'
printf 'small\n' > "$T/dev/small.txt"
VID_SHARE_SPLIT_BYTES=100000 sh checks/share.sh build --run 2026-11-s --logs "$T/dev" > "$T/out" 2>&1 || fail 'the build failed'
B=.vid/shares/2026-11-s
[ ! -e "$B/logs/big.txt" ] || fail 'the whole file is still there'
n=0; for p in "$B"/logs/big.txt.part-*; do [ -f "$p" ] || fail 'no parts'; s=$(wc -c < "$p" | tr -d ' '); [ "$s" -le 100000 ] || fail "$p is $s bytes"; n=$((n + 1)); done
[ "$n" = 3 ] || fail "$n parts, not 3"
cat "$B"/logs/big.txt.part-000 "$B"/logs/big.txt.part-001 "$B"/logs/big.txt.part-002 | cmp -s - "$T/dev/big.txt" || fail 'the parts do not rejoin to the file'
[ -f "$B/logs/small.txt" ] && [ ! -e "$B/logs/small.txt.part-000" ] || fail 'the small file was cut'
grep -q '\["logs/big.txt", 3\]' "$B/MANIFEST.json" || fail 'the manifest does not list the split'
grep -qx 'split	logs/big.txt	3' "$B.summary" || fail 'the summary does not list the split'
echo 'share-split: ok'
