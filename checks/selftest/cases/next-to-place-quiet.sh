#!/bin/sh
# Purpose: selftest case — a row the owner accepted as to place asks no question (FB-3 C5). On the toy in GitHub manual, #2 (S02) open
# and published; ROW-002, in no step, on the to-place list with a stage 1 ticket open (to-place-active), and ROW-001, in #2, on it as of
# another stage (stage-to-correct): both are counted minor, never a trigger line, never a `Q<n>` line, and planning-analysis still
# takes them in; `replan.sh scope` holds both rows, and by default both triggers with their evidence, and no other minor one. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "next-to-place-quiet: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }
printf 'ROW-002\tno-step\t2026-11-19T09:00:00Z\tyes, place it later\nROW-001\tother-stage\t2026-11-19T09:00:00Z\tyes, place it later\n' > .vid/tw/to-place
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"
for x in to-place-active:ROW-002 stage-to-correct:ROW-001; do
  grep -q "^quiet${TB}minor${TB}${x%%:*}${TB}${x#*:}${TB}.*${TB}minor\$" "$T/L" || fail "${x#*:} is not counted minor as ${x%%:*}"
  grep -q "^trigger${TB}[a-z]*${TB}${x%%:*}${TB}" "$T/L" && fail "${x#*:} is shown as a trigger"; done
grep -q "^move${TB}planning-analysis${TB}-${TB}[0-9a-f]*${TB}.*2 tests to place" "$T/L" || fail 'planning-analysis does not take in the two tests to place'
sh "$CHECKS/queue.sh" raise "$T/L" > "$T/out" 2>&1 || fail 'queue.sh raise failed'; sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
grep -q "${TB}trigger:\(to-place-active\|stage-to-correct\):" "$T/ql" && { cp "$T/ql" "$T/out"; fail 'a row on the to-place list is a question'; }
sh "$CHECKS/replan.sh" scope > "$T/sc" 2> "$T/out" || fail 'replan.sh scope failed'
grep -q "^to-place${TB}ROW-002${TB}" "$T/sc" && grep -q "^to-place${TB}ROW-001${TB}" "$T/sc" || { cp "$T/sc" "$T/out"; fail 'the scope does not hold the two rows'; }
grep -q "^trigger${TB}minor${TB}to-place-active${TB}ROW-002${TB}to-place no-step; stage 1 has an open ticket\$" "$T/sc" && grep -q "^trigger${TB}minor${TB}stage-to-correct${TB}ROW-001${TB}to-place other-stage; in #[0-9]*, step S02 of stage 1\$" "$T/sc" || { cp "$T/sc" "$T/out"; fail "the scope does not hold the two rows' ticket, step and stage"; }
! grep -E "^trigger${TB}minor${TB}" "$T/sc" | grep -qvE "${TB}(to-place-active|stage-to-correct)${TB}" || { cp "$T/sc" "$T/out"; fail 'the scope takes in another minor trigger'; }
echo 'next-to-place-quiet: ok'
