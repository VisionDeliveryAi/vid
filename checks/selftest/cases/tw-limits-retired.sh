#!/bin/sh
# Purpose: selftest case — the `retired` row state is cut (0.26.11.1.2, R5). Nothing writes it (decide.sh's hset writes failing, held,
# accepted, accepted-by-ruling, owed and known-limit), so a handed `row ROW-004 retired` line is refused as out of form, as any line the
# writer does not know; with it gone the fix ticket of ROW-003 is published, and neither it nor its meta line holds the word "retired".
# A known limit is handled as today: ROW-003 ruled a known limit with no pull request naming its ticket, the ticket is withdrawn, and the
# next fix ticket says nothing of retirement. No script under checks/, and vid-run's text where skills/ is beside it, reads `retired`
# as a row state. tw-limits.sh's set-up. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-limits-retired: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the readers: no row-state pattern or log field names retired
for s in writer plan queue; do ! grep -nE '[|(]retired[|)]|retired=|"retired"|retired\)' "$CHECKS/$s.sh" > "$T/out" || fail "$s.sh still reads retired as a row state"; done
[ ! -d "$CHECKS/../skills" ] || ! grep -n 'a known limit or retired' "$CHECKS/../skills/vid-run/SKILL.md" > "$T/out" || fail "vid-run still names retired as a settled state"
tw_toy "$T/toy"; GS=$CHECKS/github.sh; W=$CHECKS/writer.sh
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# the skeleton's round, its ticket #1 merged as pull request 2 (as close-fix plants it); S01 left open; stage 0's candidate, and stage 1's
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 2 >> .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
grep -v '^closed S01 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; tw_hand 'candidate 1'
tw_hand 'fix ROW-003 | ROW-003: ROW-003 in chromium | close #9 of S01: req-9-p1c1-1'
# red-first: a handed retired line is out of form
cp .vid/tw/handed "$T/h0"; tw_hand 'row ROW-004 retired'; L=$(grep -n '^row ROW-004 retired ' .vid/tw/handed | cut -d: -f1)
RC=0; sh "$W" write fix ROW-003 > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'the writer accepted a handed row ROW-004 retired'
grep -qF "line $L: out of form" "$T/out" || fail "the retired line was not refused as out of form (exit $RC)"
cat "$T/h0" > .vid/tw/handed
rd next; F=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out"); [ -n "$F" ] && grep -q "^published $F kind=fix step=S01 rows=ROW-003 " .vid/tw/log || fail 'the fix ticket was not published'
! grep -q "^published $F .*retired=" .vid/tw/log || fail "the fix ticket's log line holds retired=: $(grep "^published $F " .vid/tw/log)"
! grep -qi 'retire' "$T/gh/issues/$F/body" || fail "the fix ticket holds the word retired: $(grep -in 'retire' "$T/gh/issues/$F/body")"
sh "$GS" tw-sync > "$T/out" 2>&1; ok "open tickets $F\$"
# a known limit, as today: withdrawn while no pull request names its ticket
tw_hand 'row ROW-003 known-limit'
rd step; sh "$W" due > "$T/out" 2>&1 || fail 'due failed'; ok "^withdraw $F limits=ROW-003\$"
rd next; ok "^withdrawn $F\$"; [ "$(cat "$T/gh/issues/$F/state")" = CLOSED ] || fail "#$F stayed open"
tw_hand 'fix ROW-006 | ROW-006: ROW-006 in chromium | close #9 of S01: req-9-p1c1-2'
N2=$(sh "$W" write fix ROW-006 2> "$T/out") || fail "the next fix ticket was refused: $(cat "$T/out")"
! grep -qi 'retire' "$N2" "${N2%.md}.meta" || fail "the next ticket holds the word retired: $(grep -in 'retire' "$N2" "${N2%.md}.meta")"
grep -q '^kind=fix step=S01 rows=ROW-006 ' "${N2%.md}.meta" || fail "the next ticket's meta: $(head -n 1 "${N2%.md}.meta")"
exit 0
