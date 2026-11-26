#!/bin/sh
# Purpose: selftest case — the "file" answer's archive names no one (SHARE-SCRUB §2 path 9, §4.5.2). A toy share is built and
# packed. Convicts unless every entry of the archive has an empty user name and group name (tar's verbose listing shows numbers
# alone), and the user's own name is in none of its headers. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-pack-names: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"
P=$T/proj; mkdir -p "$P/checks" "$P/.vid"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'a record\n' > .vid/notes.txt
sh checks/share.sh build --run 2026-11-a > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
A=$(sh checks/share.sh pack .vid/shares/2026-11-a) || fail 'the pack failed'
[ -f "$A" ] || fail 'no archive'
me=$(id -un); grp=$(id -gn)
gzip -dc "$A" > "$T/a.tar"
# a ustar header holds the user name at offset 265 and the group name at 297, 32 bytes each
off=0; n=0; sz=$(wc -c < "$T/a.tar" | tr -d ' ')
while [ $((off + 512)) -le "$sz" ]; do
  h=$(dd if="$T/a.tar" bs=1 skip=$off count=512 2>/dev/null | od -An -c | tr -d ' \n')
  [ -n "$(printf '%s' "$h" | tr -d '\\0')" ] || break
  un=$(dd if="$T/a.tar" bs=1 skip=$((off + 265)) count=32 2>/dev/null | tr -d '\000'); gn=$(dd if="$T/a.tar" bs=1 skip=$((off + 297)) count=32 2>/dev/null | tr -d '\000')
  [ -z "$un" ] && [ -z "$gn" ] || fail "an archive entry names a user or group ($([ "$un" = "$me" ] && echo the user || echo someone))"
  fs=$(dd if="$T/a.tar" bs=1 skip=$((off + 124)) count=12 2>/dev/null | tr -d '\000 '); fs=$((0$fs)); n=$((n + 1))
  off=$((off + 512 + (fs + 511) / 512 * 512))
done
[ "$n" -gt 0 ] || fail 'the archive has no entries'
: "$grp"
echo 'share-pack-names: ok'
