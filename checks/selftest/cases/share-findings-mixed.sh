#!/bin/sh
# Purpose: selftest case — the share keeps every finding of a mixed findings file (0.26.11.1.4, R8). The form is read at each `## ` heading:
# `F-<n> · ` is the hand-written form, any other the queue's. A file with one `## F-1 · …` entry and one `## S02: …` queue entry (its
# seen, first and words lines) gives FINDINGS.md 2 findings, each with its own file; a `## Note …` heading of the queue's form is still
# skipped. FIX-BATCH-T2 §13 (OW-6): a queue entry's original id is its line in the file and its whole heading, never a number:
# a file of F-1, a queue entry, F-2 (the run's order, where the share's count gave the queue entry F-2's id), two queue entries of one step whose words differ only after their 60th character, and two
# whose headings differ only by | and / gives six findings, each with its own original id, and a table whose rows keep their
# cells. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-findings-mixed: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
P=$T/proj; mkdir -p "$P/checks" "$P/.vid"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'id=R-78\n' > .vid/run
printf '# ViD findings\n\n## F-1 · The round stops when it should wait\n\n- **Seen:** 2026-11-08 · S02\n- **Cost:** 20 min\n\n## Note on the round\n- seen: 1\n- first: 2026-11-08T10:00Z\n- words: not a finding\n\n## S02: the head report\n- seen: 3\n- first: 2026-11-08T11:00Z\n- words: covers lines missed: the report could not read them\n' > .vid/VID-FINDINGS.md
sh checks/share.sh build --run 2026-11-x > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
F=.vid/shares/2026-11-x
n=$(grep -c '^| [0-9]' "$F/FINDINGS.md" || true); [ "$n" = 2 ] || fail "$n findings, not 2: $(grep '^| [0-9]' "$F/FINDINGS.md" | tr '\n' ' ')"
grep -q '^| 1 | \[F-001\](findings/F-001.md) | The round stops when it should wait | unrated |' "$F/FINDINGS.md" || fail 'the F-1 entry is not the first finding'
grep -q '^| 2 | \[F-002\](findings/F-002.md) | covers lines missed | unrated |' "$F/FINDINGS.md" || fail 'the queue entry is not the second finding'
grep -q '^| Seen | 2026-11-08T11:00Z · S02 · seen 3 times (queue.sh defect) |$' "$F/findings/F-002.md" || fail "the queue entry's Seen is not written"
grep -q '^| Original id | F-1 in records/.vid/VID-FINDINGS.md |$' "$F/findings/F-001.md" || fail "the F-1 entry's original id is not kept"
! grep -q 'not a finding' "$F/FINDINGS.md" "$F"/findings/*.md || fail 'the Note heading was not skipped'
# OW-6: no original id is made up, none is shared, and a | in a heading does not cut the table
P2=$T/proj2; mkdir -p "$P2/checks" "$P2/.vid"; cp "$CHECKS/share.sh" "$P2/checks/"; cd "$P2"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'id=R-79\n' > .vid/run
LW='the head report names a commit the read-only copy does not hold yet, so the close'
q() { printf '\n## %s\n- seen: 1\n- first: 2026-11-09T10:00Z\n- words: %s\n' "$1" "$1"; }
{ printf '# ViD findings\n\n## F-1 · The first\n\n- **Seen:** 2026-11-09\n'; q 'S02: a queue defect'
  printf '\n## F-2 · The second\n\n- **Seen:** 2026-11-09\n'; q "S03: $LW waits"; q "S03: $LW stops"; q 'S04: a|b failed'; q 'S04: a/b failed'; } > .vid/VID-FINDINGS.md
sh checks/share.sh build --run 2026-11-y > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the second build failed'; }
F=.vid/shares/2026-11-y
n=$(grep -c '^| [0-9]' "$F/FINDINGS.md" || true); [ "$n" = 7 ] || fail "$n findings in the second file, not 7"
for f in "$F"/findings/*.md; do sed -n 's/^| Original id | \(.*\) |$/\1/p' "$f"; done > "$T/ids"
[ "$(grep -c . "$T/ids")" = 7 ] || fail "not every finding names its original id: $(cat "$T/ids" | tr '\n' ';')"
[ "$(sort "$T/ids" | uniq -d | grep -c .)" = 0 ] || fail "two findings share an original id: $(sort "$T/ids" | uniq -d | tr '\n' ';')"
grep -qx 'F-1 in records/.vid/VID-FINDINGS.md' "$T/ids" && grep -qx 'F-2 in records/.vid/VID-FINDINGS.md' "$T/ids" || fail "a numbered entry's id is not kept: $(tr '\n' ';' < "$T/ids")"
grep -q '^line [0-9][0-9]* of records/.vid/VID-FINDINGS.md, the entry "S02: a queue defect"$' "$T/ids" || fail "the queue entry's id is not its line and heading: $(tr '\n' ';' < "$T/ids")"
[ "$(grep -c '^F-' "$T/ids")" = 2 ] || fail "a queue entry was given a number: $(tr '\n' ';' < "$T/ids")"
for f in "$F"/findings/*.md; do awk -F'|' '/^\| Original id \|/ { if (NF != 4) { print FILENAME; exit 1 } }' "$f" || fail "a | in a heading cut the Original id row of $f"; done
exit 0
