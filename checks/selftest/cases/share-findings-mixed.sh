#!/bin/sh
# Purpose: selftest case — the share keeps every finding of a mixed findings file (0.26.11.1.4, R8). The form is read at each `## ` heading:
# `F-<n> · ` is the hand-written form, any other the queue's. A file with one `## F-1 · …` entry and one `## S02: …` queue entry (its
# seen, first and words lines) gives FINDINGS.md 2 findings, each with its own file; a `## Note …` heading of the queue's form is still
# skipped. Env: CHECKS.
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
exit 0
