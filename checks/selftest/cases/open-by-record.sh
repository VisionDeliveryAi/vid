#!/bin/sh
# Purpose: selftest case — an open ticket on ViD's record is open, whatever its labels (FB-3 C3). On the toy switched to GitHub manual
# with one ticket of the project's own label alone, its read kept: the status counts one ticket open and names it, the round's
# progress says open=1, and the completion's conditions (close.sh endconds) name it open; once withdrawn in ViD's log none of the three does. An issue of the
# read that is neither on record nor labelled is no ticket. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "open-by-record: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf '# DECISIONS\n\n## Log\n' > DECISIONS.md; git add DECISIONS.md; git commit -qm 'decisions'   # the round records the dev side's there
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf 'team:alpha\n' > "$FAKEGH/issues/$N1/labels"
N2=$(gh_issue 'The team, its own'); printf 'team:alpha\n' > "$FAKEGH/issues/$N2/labels"
printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; cp "$T/mo" "$T/out"
[ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
look() { sh "$CHECKS/queue.sh" status > "$T/st" 2>&1 || { cp "$T/st" "$T/out"; fail 'queue.sh status failed'; }
  sh "$CHECKS/close.sh" endconds > "$T/en" 2>&1 || :; sh "$CHECKS/round.sh" step > "$T/rs" 2>&1 || { cp "$T/rs" "$T/out"; fail 'round.sh step failed'; }; }
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
grep -q "^issue	$N1	team:alpha	" .vid/round/read && grep -q "^issue	$N2	" .vid/round/read || { cp .vid/round/read "$T/out"; fail 'the read does not hold the two issues'; }
export CLAUDE_CODE_SESSION_ID=obr; sh "$CHECKS/github.sh" lock-take obr > "$T/out" 2>&1 || fail 'no lock for the round'
look; cat "$T/st" "$T/en" "$T/rs" > "$T/out"
grep -q '^tickets: open 1 ' "$T/st" || fail "the status does not count #$N1 open: $(grep '^tickets: ' "$T/st")"
grep -q "^now: #$N1 " "$T/st" || fail "the status does not name #$N1 open: $(grep '^now: ' "$T/st")"
grep -q '^progress: .* open=1 ' "$T/rs" || fail "the round does not count #$N1 open: $(grep '^progress: ' "$T/rs")"
grep -q "ticket #$N1 open" "$T/en" || fail "the completion does not name #$N1 open"
grep -q "#$N2 open" "$T/en" && fail 'an issue neither on record nor labelled is called a ticket'
printf 'withdrawn %s at=2026-11-20T09:00:00Z\n' "$N1" >> .vid/tw/log
look; cat "$T/st" "$T/en" "$T/rs" > "$T/out"
grep -q '^tickets: open 0 ' "$T/st" && grep -q '^now: no open ticket' "$T/st" && grep -q '^progress: .* open=0 ' "$T/rs" && ! grep -q "ticket #$N1 open" "$T/en" || fail 'a withdrawn ticket is counted open'
echo 'open-by-record: ok'
