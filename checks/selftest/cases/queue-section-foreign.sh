#!/bin/sh
# Purpose: selftest case — the question section is the queue's alone (0.26.11.1.3, R4), checks/queue.sh on the writer's toy and the fake gh.
# RUN-STATE's "Open product questions" holds a hand-written `- none (Q3 answered …)` line, a session's own planning Q line and a note,
# beside the section's comment: after `queue.sh sync` the hand-written line and the note are gone, each named on standard error; the
# planning Q line and the comment stay, and the queue's own line is written. With no question open at all, nothing but the comment is
# under the heading. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-section-foreign: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; QS=$CHECKS/queue.sh
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide
grep -v '^context-window ' .vid/metrics-events > "$T/me" || true; cat "$T/me" > .vid/metrics-events   # the compaction question unanswered: one queue line of its own
sec() { awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' .vid/RUN-STATE.md | awk '/<!--/ { c = 1 } !c && NF { print } /-->/ { c = 0 }'; }
# plant <lines>: the section's body, after its comment
plant() { printf '%s\n' "$1" > "$T/pl"; awk -v L="$T/pl" '/^## Open product questions/ { print; print ""; print "<!-- one line per question -->"; while ((getline l < L) > 0) print l; close(L); on = 1; next } on && /^## / { on = 0; print ""; print; next } on { next } { print }' .vid/RUN-STATE.md > "$T/rs"
  grep -q '^## Open product questions' "$T/rs" || printf '\n## Open product questions\n\n<!-- one line per question -->\n%s\n' "$1" >> "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md; }
P='- Q7 · asked 2026-11-10T09:00:00Z · gates all remaining work · Is the plan weekly or monthly?'
plant "- none (Q3 answered 2026-11-10, see the PRD)
$P
the owner said to wait until Monday"
RC=0; sh "$QS" sync > "$T/out" 2> "$T/err" || RC=$?; [ "$RC" = 0 ] || { cat "$T/err" >> "$T/out"; fail "sync failed ($RC)"; }
sec > "$T/sec"; cp "$T/sec" "$T/out"
! grep -qF -- '- none (Q3 answered' "$T/sec" || fail 'the hand-written line survived the sync'
! grep -qF 'wait until Monday' "$T/sec" || fail 'the note survived the sync'
grep -qxF -- "$P" "$T/sec" || fail "the session's planning Q line was not kept"
grep -q '^- Q[0-9]* · asked .* · gates nothing · may ViD set' "$T/sec" || fail "the queue's own line was not written"
grep -qF -- '- none (Q3 answered 2026-11-10, see the PRD)' "$T/err" && grep -qF 'the owner said to wait until Monday' "$T/err" || { cp "$T/err" "$T/out"; fail 'the sync did not name each line it dropped'; }
grep -q '<!-- one line per question -->' .vid/RUN-STATE.md || fail "the section's comment went"
# a second sync names nothing more and moves nothing
cp .vid/RUN-STATE.md "$T/rs1"; sh "$QS" sync > "$T/out" 2> "$T/err" || true; [ ! -s "$T/err" ] || { cp "$T/err" "$T/out"; fail 'a second sync named a line'; }; cmp -s "$T/rs1" .vid/RUN-STATE.md || fail 'a second sync moved the section'
# no question open at all: nothing under the heading
mkdir -p .claude; printf '{\n  "autoCompactWindow": 300000\n}\n' > .claude/settings.json
plant "- none (Q3 answered 2026-11-10)"; sh "$QS" sync > "$T/out" 2> "$T/err" || fail 'sync failed with no question open'
[ -z "$(sec)" ] || { sec > "$T/out"; fail 'with no question open, the section holds a line'; }
exit 0
