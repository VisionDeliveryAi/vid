#!/bin/sh
# Purpose: selftest case — triggers declined (GM-2 T9). On the planner's toy in GitHub manual, #2 (S02, stage 1) published
# and open; ROW-021 and ROW-022, of stage 1, added to S04 after the applied commit, each an important added-active trigger.
# `next.sh decline added-active "<words>"` declines the kind: one line in .vid/next/declined for each of its two subjects,
# `kind` in the fifth field, the words kept. At the next call both are counted declined, not shown. ROW-023 added to S04,
# a third subject of that kind, is raised and shown; the two are not. ROW-021's line then changes, and it is raised again.
# A decline with no words, or of a kind not raised, is refused, writing nothing. ROW-022 is then handled (taken
# out of the inventory and the plan), so at the next call, a read with no unread line, `shown` drops its decline; added back
# as it was, it is a trigger raised anew, and shown. That is proved with no handed record, so every call
# holds an `unread due` line, which hides no trigger; a call whose read holds an `unread round` line keeps the decline; and
# `shown` given lines with no `tiers` line, as a failed `triggers` leaves, drops nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-decline: $*" >&2; cat "$T/tr" >&2 2>/dev/null; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied; : > .vid/tw/handed
printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-18T09:00:00Z\n' > .vid/tw/log
printf '# Step ticket S02\n\n## Rows\n\n> %s\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" "$(grep '^ROW-005 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
{ printf 'issue\t2\tticket\tvid: claimed by the team\t2026-11-18T09:00:00Z\n'; printf 'ticket\t2\tOPEN\t-\t2026-11-18T09:00:00Z\n'; printf 'body\t2\t%s\n' '## Tests' '- ROW-001' '- ROW-005'; } > .vid/next/read
row() { pt_rs "s/^\\(step S04 .*rows: .*\\)RULE-004 /\\1RULE-004 $1 /"; pt_after "$2" "$1 | behavior | REQ-001 | anonymous | n/a | $3 | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; }
row ROW-021 ROW-020 'A saved search shows the day its last digest went out. Fails if a saved search shows no day.'
row ROW-022 ROW-021 'A saved search shows how many jobs its last digest held. Fails if the count is missing.'
grep -q '^step S04 .*ROW-022 ROW-021' .vid/RUN-STATE.md && grep -q '^ROW-022 ' INVENTORY.md || fail 'ROW-021 and ROW-022 did not land'
call() { sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'; sh "$CHECKS/next.sh" shown "$T/tr" > "$T/out" 2>&1 || fail 'next.sh shown failed'; }
shown() { grep -q "^trigger${TB}important${TB}added-active${TB}$1${TB}" "$T/tr"; }
declined() { grep -q "^quiet${TB}important${TB}added-active${TB}$1${TB}.*${TB}declined\$" "$T/tr" && ! shown "$1"; }
call; shown ROW-021 && shown ROW-022 || fail 'ROW-021 and ROW-022 are not shown before the decline'
# refusals write nothing
RC=0; sh "$CHECKS/next.sh" decline added-active '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a decline with no words was taken'
RC=0; sh "$CHECKS/next.sh" decline reset-taken 'not now' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a decline of a kind not raised was taken'
[ ! -s .vid/next/declined ] || fail "a refused decline wrote: $(cat .vid/next/declined)"
sh "$CHECKS/next.sh" decline added-active 'these wait for the next stage' > "$T/out" 2>&1 || fail 'the decline was refused'
for r in ROW-021 ROW-022; do grep -q "^added-active${TB}$r${TB}important${TB}[0-9a-f]\{40\}${TB}kind${TB}[0-9T:Z-]*${TB}these wait for the next stage\$" .vid/next/declined || fail "no declined line for $r by kind: $(cat .vid/next/declined)"; done
[ "$(grep -c . .vid/next/declined)" = 2 ] || fail "the decline wrote other than its two subjects: $(cat .vid/next/declined)"
call; declined ROW-021 && declined ROW-022 || fail 'a declined subject is shown, or not counted declined'
grep -q "^tiers${TB}.*declined=2\$" "$T/tr" || fail "the two are not counted declined: $(grep '^tiers' "$T/tr")"
# a third subject of the kind is raised; the two are not
row ROW-023 ROW-022 'A saved search names the feed each job came from. Fails if a job names no feed.'
call; shown ROW-023 || fail 'ROW-023, a subject not declined, is not raised'; declined ROW-021 && declined ROW-022 || fail 'a declined subject is raised again with nothing grown'
# a declined subject whose line changes is raised again
sed 's/^\(ROW-021 .*\)Fails if a saved search shows no day\./\1Fails if a saved search shows no day, or a wrong one./' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
call; shown ROW-021 || fail 'ROW-021, declined and since changed, is not raised again'; declined ROW-022 || fail 'ROW-022, unchanged, is raised again'
# handled: ROW-022 no longer raised, its decline dropped; raised anew, shown
cp .vid/next/declined "$T/dc0"; : > "$T/empty"; sh "$CHECKS/next.sh" shown "$T/empty" > "$T/out" 2>&1 || fail 'next.sh shown failed on empty lines'
cmp -s "$T/dc0" .vid/next/declined || fail "shown, given no tiers line, changed the declines: $(cat .vid/next/declined)"
rm -f .vid/tw/handed
L22=$(grep '^ROW-022 ' INVENTORY.md); pt_del ROW-022; ! grep -q '^ROW-022 ' INVENTORY.md || fail 'ROW-022 was not taken out'
cp .vid/next/read "$T/rd0"; printf 'unread\tround\t-\tnext-read exited 1: the read was cut\n' >> .vid/next/read
call; grep -q "^added-active${TB}ROW-022${TB}" .vid/next/declined || fail 'the decline of ROW-022 was dropped at a call whose read failed'
cp "$T/rd0" .vid/next/read
call; ! grep -q "^[a-z]*${TB}[a-z]*${TB}added-active${TB}ROW-022${TB}" "$T/tr" || fail 'ROW-022, taken out, is still raised'
grep -q "^unread${TB}due${TB}" "$T/tr" || fail 'with no handed record, the call holds no unread due line'
! grep -q "^added-active${TB}ROW-022${TB}" .vid/next/declined || fail "the decline of ROW-022, no longer raised, was kept: $(cat .vid/next/declined)"
grep -q "^added-active${TB}ROW-021${TB}" .vid/next/declined || fail "the decline of ROW-021, still raised, was dropped"
pt_rs 's/^\(step S04 .*rows: .*\)RULE-004 /\1RULE-004 ROW-022 /'; pt_after ROW-021 "$L22"; [ "$(grep '^ROW-022 ' INVENTORY.md)" = "$L22" ] || fail 'ROW-022 did not come back as it was'
call; shown ROW-022 || fail 'ROW-022, handled and raised anew with the same evidence, stays hidden'
exit 0
