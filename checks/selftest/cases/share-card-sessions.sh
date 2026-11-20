#!/bin/sh
# Purpose: selftest case — the run card says what it knows of the run (0.26.11.1.4, R8). Three session events (S-a, S-b, S-c; S-a with its
# transcript) carry two ViD versions; a further transcript, S-d, is taken with --session and named by no event. RUN.md's "Who and what"
# lists 4 sessions, each once: the events' three with their models, and S-d with its model from the bundle's statistics; role and
# machine stay unknown. The version line names each vid= the session events carry and the time of the last session event, a later one
# with vid=- (its version unread) included, never a bare version.
# The manifest still names the last version alone. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-card-sessions: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'id=R-79\n' > .vid/run
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); D=$PR/$E; mkdir -p "$D" "$PR/elsewhere"
a() { printf '{"type":"assistant","timestamp":"%s","isSidechain":false,"message":{"id":"%s","model":"%s","usage":{"input_tokens":1,"cache_creation_input_tokens":1,"cache_read_input_tokens":1,"output_tokens":1}}}\n' "$@"; }
a 2026-11-08T10:00:00.000Z msg_a claude-opus-5-5 > "$D/S-a.jsonl"
a 2026-11-08T13:00:00.000Z msg_d claude-sonnet-5-5 > "$PR/elsewhere/S-d.jsonl"
{ printf 'session id=S-a source=startup model=claude-opus-5-5 transcript=%s vid=0.26.10.29.1 at=2026-11-08T10:00:00Z\n' "$D/S-a.jsonl"
  printf 'session id=S-b source=startup model=claude-opus-5-5 vid=0.26.10.29.1 at=2026-11-08T11:00:00Z\n'
  printf 'session id=S-c source=resume model=claude-opus-5-5 vid=0.26.10.29.2 at=2026-11-08T12:00:00Z\n'
  printf 'step-start step=S01 at=2026-11-08T12:30:00Z\n'
  printf 'session id=S-c source=resume model=claude-opus-5-5 vid=- at=2026-11-08T12:45:00Z\n'; } > .vid/metrics-events
sh checks/share.sh build --run 2026-11-c --session S-d > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-c; [ -f "$B/conversations/S-d/S-d.jsonl.gz" ] || fail "S-d's transcript is not in the share"
awk '/^## Who and what/ { s = 1; next } s && /^## / { exit } s && /^\| S-/' "$B/RUN.md" > "$T/rows"
[ "$(grep -c . "$T/rows")" = 4 ] || fail "$(grep -c . "$T/rows") session rows, not 4: $(tr '\n' ' ' < "$T/rows")"
for s in S-a S-b S-c; do grep -qx "| $s | unknown | unknown | claude-opus-5-5 |" "$T/rows" || fail "no row for $s with its model"; done
grep -qx '| S-d | unknown | unknown | claude-sonnet-5-5 |' "$T/rows" || fail "no row for S-d, with its model from the statistics"
grep -qx '^- \*\*ViD version:\*\* 0.26.10.29.1, 0.26.10.29.2, as of the last session event, 2026-11-08T12:45:00Z$' "$B/RUN.md" || fail "the version line: $(grep 'ViD version' "$B/RUN.md")"
grep -q '"vid": "0.26.10.29.2"' "$B/MANIFEST.json" || fail 'the manifest does not name the last version'
exit 0
