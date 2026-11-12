#!/bin/sh
# Purpose: selftest case — the status block reads well to a new user (0.26.10.28.5, R3), on TW's toy, a made-up record set early in the run with
# nothing open: no field is a bare colon or a name with nothing after it — "steps waiting", "steps closed", "closes out", "open questions", "flags",
# the delegated answers — each says none in words; the end line reads "end: not yet, stage <n> of <m>" while the final stage has no candidate, not a
# count of unmet conditions; the findings page is named by what it is, not as a path inside ViD's folder. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "status-words: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide/queue; sh "$GS" round-read > .vid/round/read 2> "$T/out" || fail 'round-read failed'
grep -q '^stage:' .vid/RUN-STATE.md || sed -i.b '1a\
stage: 1' .vid/RUN-STATE.md
VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail "status failed: $(tail -n 2 "$T/out")"
grep -q '^== where things stand' "$T/out" || fail 'no status block'
B=$(grep -nE ':[[:space:]]*$|:[[:space:]]+·|·[[:space:]]*$|[[:space:]]{2,}·| steps waiting[[:space:]]*($|·)' "$T/out" || true); [ -z "$B" ] || fail "a bare field: $B"
grep -q '^tickets: open 0 · merged 0 · items for the owner 0 · steps waiting none$' "$T/out" && grep -q '^steps closed: none · closes out: none$' "$T/out" && grep -q '^open questions: none$' "$T/out" && grep -q '^flags: no flags$' "$T/out" || fail 'an empty field does not say so in words'
grep -q '^delegated answers since the last update: none$' "$T/out" || fail 'no delegated answers is not said'
grep -qE '^end: not yet, stage [0-9]+ of [0-9]+$' "$T/out" && ! grep -q 'conditions unmet' "$T/out" || fail "the end line before the final stage's candidate: $(grep '^end:' "$T/out")"
! grep -q '\.vid/decide/queue.html' "$T/out" && grep -q '^the findings page: one page of the held rows with their records; ask to open it in your browser$' "$T/out" || fail "the findings page: $(grep 'findings page' "$T/out")"
echo 'status-words: ok'
