#!/bin/sh
# Purpose: selftest case — the scan after the build, and binaries (0.26.10.28.7, stage 3 R3). A toy project's share is built clean;
# `share.sh scan` on it exits 0. Then the case alters the bundle as a later hand might: a token added to a record, a key added
# inside a gzipped transcript, a user name after a home prefix added to a log, a value added to one part of a split file.
# Convicts unless `share.sh scan` exits non-zero naming each altered file and its kind, and prints none of the added values;
# `share.sh pack` refuses the altered bundle and writes no archive. A binary record and a binary log (NUL bytes), and a gzip
# whose content is binary, are left out and listed in the manifest and the summary, never copied; a gzip whose content is text
# is read, redacted and kept gzipped. A literal in a left-out binary's name and a text file's name is nowhere
# (summary, manifest, paths, output); a split part with no .part-000 is read by the scan; a bundle scanned away from its
# .known is refused. A value in a file's name is never printed, the scan naming the file by its redacted path.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-scan: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
U=Users; HN=fenwick; export HOME="$T/h/$U/$HN"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/screens" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'a record\n' > .vid/notes.md
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E"; printf '{"type":"user","n":1}\n' > "$PR/$E/S-a.jsonl"
printf 'session id=S-a source=startup transcript=%s at=2026-11-07T10:00:00Z\n' "$PR/$E/S-a.jsonl" > .vid/metrics-events
printf '\211PNG\r\n\032\n\000\000\000\rIHDR' > .vid/screens/shot.png; printf 'ELF\000\001\002' > "$T/dev/tool.bin"
printf 'bin\000ary' | gzip > "$T/dev/blob.gz"; T1="ghp""_$(awk 'BEGIN { for (i = 0; i < 30; i++) printf "t" }')"
printf 'token %s in a gzipped log\n' "$T1" | gzip > "$T/dev/run.log.gz"
awk 'BEGIN { for (i = 0; i < 4000; i++) printf "%049d\n", i }' > "$T/dev/big.txt"
# a literal in a left-out binary's name and in a text file's name
T7="gh""p_$(awk 'BEGIN { for (i = 0; i < 30; i++) printf "m" }')"; printf 'x\n' > "$T/dev/$T7-a.txt"
LT=ReviewLiteral824; printf '%s\n' "$LT" > "$T/lits"; mkdir -p .vid/notes; printf 'x\000y' > ".vid/notes/$LT.bin"; printf 'plain notes\n' > "$T/dev/$LT-notes.txt"
VID_SHARE_SPLIT_BYTES=100000 sh checks/share.sh build --run 2026-11-c --logs "$T/dev" --redact-file "$T/lits" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-c
sh checks/share.sh scan "$B" > "$T/scan" 2>&1 || { cat "$T/scan" >&2; fail 'the scan of the clean bundle failed'; }
grep -q '^left-out	records/.vid/notes/\[REDACTED:literal\].bin	' "$B.summary" || fail "the left-out binary's row does not hide the literal"
( cd "$B" && find . | while IFS= read -r f; do printf '%s\n' "$f"; [ ! -f "$f" ] || case "$f" in *.gz) gzip -dc "$f" ;; *) cat "$f" ;; esac; done ) > "$T/all"
cat "$B.summary" "$B/MANIFEST.json" "$T/out" "$T/scan" >> "$T/all"; N=$(grep -cF -e "$LT" -e "$T7" "$T/all" || true); [ "$N" = 0 ] || fail "the literal or a token in a name is left on $N lines of the bundle, its paths, the summary, the manifest or the output"
# the integration's final review: a quoted password ending in escaped backslashes, inside a JSON string, is found; the plant then removed
P8="bsS$(awk 'BEGIN { for (i = 0; i < 12; i++) printf "q" }')"; X='\'; printf '%s\n' "{\"type\":\"user\",\"content\":\"password=$X\"ab $P8$X$X$X$X$X\"${X}nmore\"}" > "$B/records/plant.jsonl"
RC=0; sh checks/share.sh scan "$B" > "$T/scan8" 2>&1 || RC=$?; rm -f "$B/records/plant.jsonl"
[ "$RC" -ne 0 ] && grep -q '^records/plant.jsonl	' "$T/scan8" && ! grep -qF -- "$P8" "$T/scan8" || fail "the scan passed a password ending in escaped backslashes: $(cat "$T/scan8")"
# a single-quoted value ending in a backslash, a backslash being literal in single quotes, inside a JSON string; then plain
for f in json plain; do P9="sqS$(awk 'BEGIN { for (i = 0; i < 12; i++) printf "r" }')$f"
  if [ "$f" = json ]; then printf '%s\n' "{\"type\":\"user\",\"content\":\"password='ab $P9$X$X'${X}nmore\"}"; else printf '%s\n' "password='ab $P9$X'"; fi > "$B/records/plant9.txt"
  RC=0; sh checks/share.sh scan "$B" > "$T/scan9" 2>&1 || RC=$?; rm -f "$B/records/plant9.txt"
  [ "$RC" -ne 0 ] && grep -q '^records/plant9.txt	' "$T/scan9" && ! grep -qF -- "$P9" "$T/scan9" || fail "the scan passed a single-quoted password ending in a backslash ($f): $(cat "$T/scan9")"; done
# a bundle scanned away from its .known is refused, naming no value
cp -R "$B" "$T/elsewhere"; RC=0; sh checks/share.sh scan "$T/elsewhere" > "$T/scan2" 2>&1 || RC=$?
[ "$RC" -ne 0 ] && grep -q 'known' "$T/scan2" || fail 'a bundle away from its .known scanned clean'
! grep -qF "$LT" "$T/scan2" || fail 'the refusal printed a value'
# binaries left out and listed; the text gzip read and redacted
for f in records/.vid/screens/shot.png logs/tool.bin logs/blob.gz; do
  [ ! -e "$B/$f" ] || fail "the binary $f was copied"
  grep -q "\[\"$f\", \"binary: not text" "$B/MANIFEST.json" || fail "the manifest does not list $f as a binary left out"
  grep -q "^left-out	$f	binary: not text" "$B.summary" || fail "the summary does not list $f"
done
gzip -dc "$B/logs/run.log.gz" | grep -qx 'token \[REDACTED:github-token\] in a gzipped log' || fail 'the text gzip was not read and redacted'
[ -f "$B/logs/big.txt.part-001" ] || fail 'no split file to alter'
# the bundle altered after its build
T2="xo""xb-$(awk 'BEGIN { for (i = 0; i < 20; i++) printf "9" }')"; T3="sk-""ant-$(awk 'BEGIN { for (i = 0; i < 24; i++) printf "u" }')"; T4="AK""IA$(awk 'BEGIN { for (i = 0; i < 16; i++) printf "Q" }')"
printf 'added %s\n' "$T2" >> "$B/records/.vid/notes.md"
{ gzip -dc "$B/conversations/S-a/S-a.jsonl.gz"; printf '{"content":"key %s"}\n' "$T3"; } | gzip > "$T/x.gz"; mv "$T/x.gz" "$B/conversations/S-a/S-a.jsonl.gz"
printf 'cwd /%s/%s/work\n' "$U" "$HN" >> "$B/logs/notes.txt"
printf 'id %s\n' "$T4" >> "$B/logs/big.txt.part-001"
T5="gh""p_$(awk 'BEGIN { for (i = 0; i < 30; i++) printf "o" }')"; printf 'orphan %s\n' "$T5" > "$B/logs/leak.txt.part-001"   # a part with no .part-000
T6="gh""p_$(awk 'BEGIN { for (i = 0; i < 30; i++) printf "n" }')"; printf 'a note\n' > "$B/logs/$T6-notes.txt"   # a value in a file's name
RC=0; sh checks/share.sh scan "$B" > "$T/scan" 2>&1 || RC=$?
grep -q '^logs/leak.txt.part-001	github-token	1$' "$T/scan" || fail 'the scan does not read the orphan part'
! grep -qF -- "$T5" "$T/scan" || fail 'the scan printed the orphan value'
grep -qx 'logs/\[REDACTED:github-token\]-notes.txt	value in the path	1' "$T/scan" || fail 'the scan does not name the value in a path by its redacted path'
! grep -qF -- "$T6" "$T/scan" || fail 'the scan printed the value in a path'
[ "$RC" -ne 0 ] || fail 'the scan of the altered bundle exited 0'
grep -q '^records/.vid/notes.md	slack-token	1$' "$T/scan" || fail 'the scan does not name the record and its kind'
grep -q '^conversations/S-a/S-a.jsonl.gz	anthropic-key	1$' "$T/scan" || fail 'the scan does not name the gzipped transcript and its kind'
grep -q '^logs/notes.txt	user-name	1$' "$T/scan" || fail 'the scan does not name the log and the user name'
grep -q '^logs/big.txt.part-000	aws-key	1$' "$T/scan" || fail 'the scan does not name the split file and its kind'
for x in "$T2" "$T3" "$T4" "$HN"; do ! grep -qF -- "$x" "$T/scan" || fail 'the scan printed a value'; done
RC=0; sh checks/share.sh pack "$B" > "$T/pack" 2>&1 || RC=$?
[ "$RC" -ne 0 ] || fail 'pack packed the altered bundle'
[ ! -e "$B.tar.gz" ] || fail 'an archive was written'
for x in "$T2" "$T3" "$T4" "$T6"; do ! grep -qF -- "$x" "$T/pack" || fail 'pack printed a value'; done
echo 'share-scan: ok'
