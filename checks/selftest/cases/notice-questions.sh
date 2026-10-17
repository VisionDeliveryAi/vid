#!/bin/sh
# Purpose: selftest case — the owner is told of a new question (v0.9.5 spec
# 3.5, R5; §7 case 1). A toy run with fresh activity (so nothing is quiet)
# and two new `Q<n>` lines. Convicts unless one tick sends ONE notice
# naming both questions with what each holds up and the run's state, the
# next tick sends nothing, a question re-asked under a reused number (a new
# `asked` time) is notified on its own, a `questions:` count that
# disagrees with the lines gives one "can't be read" notice, and so does a
# line written `Q3:`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=notice-questions
. "$CHECKS/selftest/fixtures/observer-lib.sh"
reset
hb "$(ago 5)" 'working on the feed'
Q1="- Q1 · asked $(ago 40) · gates ROW-004, ROW-005 · Should a digest go out when nothing changed?"
Q2="- Q2 · asked $(ago 30) · gates app/billing · Is a refund allowed after thirty days?"
rs active "$Q1
$Q2"
tick
[ "$(nnote)" -eq 1 ] || fail 'the two new questions are not one notice'
grep -q 'Q1: Should a digest go out when nothing changed? — it holds up ROW-004, ROW-005' "$T/notify.log" || fail 'Q1 or its gates missing'
grep -q 'Q2: Is a refund allowed after thirty days? — it holds up app/billing' "$T/notify.log" || fail 'Q2 or its gates missing'
grep -q 'the build is still going' "$T/notify.log" || fail 'the run state is missing'
tick; [ "$(nnote)" -eq 1 ] || fail 'a question was told twice'
Q1B="- Q1 · asked $(ago 2) · gates all remaining work · Which currency do invoices use?"
rs active "$Q1B
$Q2"
tick; [ "$(nnote)" -eq 2 ] || fail 'a question re-asked under a reused number was not told'
tail -n 1 "$T/notify.log" | grep -qx "ViD: a question is waiting — Which currency do invoices use? — it holds up all remaining work; the build is still going. Answer it in the build's session." || fail 'the one-question text'
rs active "$Q1B
$Q2" '3 open · next Q9'
tick; [ "$(nnote "can't be read")" -eq 1 ] || fail 'a count that disagrees with the lines gave no notice'
tick; [ "$(nnote "can't be read")" -eq 1 ] || fail 'the unreadable-list notice repeated'
rs active "$Q1B
$Q2"
tick; [ "$(nnote "can't be read")" -eq 1 ] || fail 'a readable list gave a notice'
rs active "$Q1B
$Q2
Q3: is the export weekly?" '3 open · next Q9'
tick; [ "$(nnote "can't be read")" -eq 2 ] || fail 'a line written Q3: gave no notice'
[ ! -f .vid/NUDGE ] || fail 'a question was nudged'
exit 0
