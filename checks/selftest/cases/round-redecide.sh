#!/bin/sh
# Purpose: selftest case — the round's re-decide (v0.26.10.28.6, R4), checks/round.sh on the toy and the fake gh. Red first at 5b39465: a new
# answer about one pull request re-decides it alone, the other decided pull request untouched; a re-decide equal to the decision posted at that
# head is not posted again; a sort pushed after the read, the read unchanged, is fetched before the re-decide and the decision posted names it.
# Kept: a question's answer that lifts a blocked label re-decides that pull request and posts the change, for a question asked on the pull request
# and for one asked on its ticket's issue; a second ask at the same head with an unchanged decision is answered. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "round-redecide: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code; mkdir -p "$T/r"
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* failed ($RC)"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; grep -q '^published 1$' "$T/out" || fail 'the skeleton ticket was not published'
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null
br() { git -C "$W" checkout -q -B "$1" origin/main 2>/dev/null; git -C "$W" -c user.name=a -c user.email=a@b commit -q --allow-empty -m "$1"; git -C "$W" push -q -f origin "$1"; git -C "$W" rev-parse HEAD; }
pr() { gh pr create -R $R --head "$1" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$2")" | sed 's/.*\///'; }
ask() { printf 'vid: decide %s\nby: MR\n' "$2" > "$T/c"; gh pr comment "$1" -R $R --body-file "$T/c" > /dev/null; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rep() { Q=$1; H=$2; shift 2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 2' "$H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases "$@")"; send "$Q"; }
cm() { ls "$T/gh/prs/$1/comments" | wc -l | tr -d ' '; }
last() { cat "$T/gh/prs/$1/comments/$(ls "$T/gh/prs/$1/comments" | sort -n | tail -n 1)"; }
dl() { awk -F'\t' -v p="$1" '$2 == p' .vid/decide/log | wc -l | tr -d ' '; }
an() { mkdir -p .vid/decide/queue; printf '2026-11-12T00:00:00Z\t%s\t-\tthe answer\towner\tanswered\n' "$1" >> .vid/decide/queue/answers; }
# two pull requests of the skeleton ticket, each with its head report; A's grade keeps both rows, B's breaches one, so B waits on a sort
mk() { H=$(br "$1"); P=$(pr "$1" 1); h=$(printf %s "$H" | cut -c1-12); rr_put "pr-$P-$h-1" faults/ROW-003/cases-alpha.xml "$(rr_cases ROW-003=fail:gone)"
  rep "pr-$P-$h-1" "$H" ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass; rr_put "grade-pr-$P-$h-1" grade.txt "$(printf 'by: GR\ncommit: %s\n%s' "$H" "$2")"; send "grade-pr-$P-$h-1"; echo "$P $H $h"; }
set -- $(mk ta 'ROW-003 kept — a
ROW-004-T1 kept — b'); PA=$1; HA=$2; ha=$3
set -- $(mk tb 'ROW-003 breached product — the page shows the wrong total
ROW-004-T1 kept — b'); PB=$1; HB=$2; hb=$3
ask "$PA" "$HA"; ask "$PB" "$HB"; rd step; grep -q "^decided $PA " "$T/out" && grep -q "^decided $PB " "$T/out" || fail 'the two asks were not both decided'
last "$PB" | grep -q 'sort evidence missing — no sort report' || fail "B's decision names no missing sort: $(last "$PB")"
# red first: an answer to a question asked on A re-decides A alone, and A's unchanged decision is not posted again
a0=$(dl "$PA"); b0=$(dl "$PB"); ca=$(cm "$PA"); cb=$(cm "$PB"); an "question:$PA:1"; rd step
[ "$(dl "$PA")" -gt "$a0" ] || fail 'the pull request the answer touches was not decided again'
[ "$(dl "$PB")" = "$b0" ] || fail 'a pull request no answer touches was decided again'
[ "$(cm "$PA")" = "$ca" ] && [ "$(cm "$PB")" = "$cb" ] || fail 'a decision equal to the one posted at that head was posted again'
! grep -q "^decided $PA " "$T/out" || fail 'an unchanged re-decide printed decided'
# red first: B's sort pushed after the read; the read is unchanged, so only the re-decide's own fetch can bring it
rr_put "sort-pr-$PB-$hb-1" sorted.txt "$(printf 'by: SR\ncommit: %s\nROW-003 note it — it fits the row — ROW-003 breached product — the page shows the wrong total' "$HB")"; send "sort-pr-$PB-$hb-1"
cb=$(cm "$PB"); an "question:$PB:2"; rd step
[ "$(cm "$PB")" -gt "$cb" ] && ! last "$PB" | grep -q 'sort evidence missing' || fail "the re-decide did not read the sort pushed after the read: $(last "$PB")"
grep -q "^decided $PB " "$T/out" || fail 'the changed re-decide printed no decided line'
# kept: a question asked on the pull request, its blocked label lifted by the answer: that pull request decided again, the change posted
printf 'blocked\n' > "$T/gh/prs/$PA/labels"; ask "$PA" "$HA"; rd step; last "$PA" | grep -q 'question open' || fail "a blocked pull request's decision names no open question: $(last "$PA")"
printf '' > "$T/gh/prs/$PA/labels"; ca=$(cm "$PA"); an "question:$PA:3"; rd step
[ "$(cm "$PA")" -gt "$ca" ] && ! last "$PA" | grep -q 'question open' || fail "the lifted label on the pull request was not decided again: $(last "$PA")"
# kept: a question asked on the ticket's issue, its label lifted: the issue's open pull request decided again, the change posted
gh issue edit 1 -R $R --add-label blocked > /dev/null; ask "$PA" "$HA"; rd step; last "$PA" | grep -q 'question open' || fail "a blocked issue's decision names no open question: $(last "$PA")"
gh issue edit 1 -R $R --remove-label blocked > /dev/null; ca=$(cm "$PA"); an "question:1:4"; rd step
[ "$(cm "$PA")" -gt "$ca" ] && ! last "$PA" | grep -q 'question open' || fail "the lifted label on the issue was not decided again: $(last "$PA")"
# kept: a second ask at the same head, the decision unchanged, is answered
ca=$(cm "$PA"); ask "$PA" "$HA"; ca=$((ca + 1)); rd step; [ "$(cm "$PA")" -gt "$ca" ] && grep -q "^decided $PA " "$T/out" || fail 'a second ask at the same head was not answered'
exit 0
