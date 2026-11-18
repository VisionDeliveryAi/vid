#!/bin/sh
# Purpose: selftest case — a ticket a plan change withdraws or takes rows out of, while its pull request is open (0.26.10.29.2 R3),
# checks/round.sh, writer.sh and github.sh on TW's toy and the fake gh. S02's ticket has an open pull request, decided; a plan change
# plans S02 again as S07: the round withdraws it, and its pull request gets one comment naming the change and where its rows went;
# a later `vid: decide` there is never decided. S07's ticket, a step's first, names it (`- earlier work: ticket #<n>, pull request
# #<p>`), keeps its T5 and its title. A split takes HOS-005 out of S03's ticket, whose pull request is open: S03's ticket is amended,
# S06's names it, and S03's pull request is still decided. The line is no refusal on a fix ticket either. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "tw-handover: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code; mkdir -p "$T/r"
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
chg() { sh "$CHECKS/plan.sh" change "$1" "$2" --trigger scope-change --evidence "$3" --expect "$4" > "$T/out" 2>&1 || fail "the plan change '$2' was refused"; sed -n 's/.*decision=\([^ ]*\).*/\1/p' "$T/out" | head -n 1; }
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 90 >> .vid/decide/merged-prs; printf '90\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
sed 's/^open-tickets: 2$/open-tickets: 3/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
tw_start S02 && tw_post step S02 || fail "S02's ticket failed"; N2=$TW_N
# the dev side's branch and pull request for a ticket, and its `vid: decide` at a new head with a report there
Wd=$T/w; git clone -q "$T/code.git" "$Wd" 2>/dev/null
head_() { git -C "$Wd" checkout -q -B "$1" "origin/$1" 2>/dev/null || git -C "$Wd" checkout -q -B "$1" origin/main 2>/dev/null; git -C "$Wd" -c user.name=a -c user.email=a@b commit -q --allow-empty -m "$1"; git -C "$Wd" push -q -f origin "$1"; git -C "$Wd" rev-parse HEAD; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
ask() { h=$(printf %s "$3" | cut -c1-12); rr_put "pr-$1-$h-1" results.txt "$(printf 'by: TM\ncommit: %s\nengines: chromium\nenvironments: 2' "$3")"; rr_put "pr-$1-$h-1" cases-chromium.xml "$(rr_cases "$2=fail:broke" ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass)"; send "pr-$1-$h-1"
  printf 'vid: decide %s\nby: MR\n' "$3" > "$T/c"; gh pr comment "$1" -R $R --body-file "$T/c" > /dev/null; }
H2=$(head_ tk2); P2=$(gh pr create -R $R --head tk2 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$N2")" | sed 's/.*\///'); gh pr ready "$P2" -R $R
ask "$P2" ROW-001 "$H2"; rd step; ok "^decided $P2 "
# a plan change plans S02 again as S07: the round withdraws #N2 and tells its pull request
pt_rs 's/^step S02 | name: new jobs only, each listed once/step S07 | name: new jobs only, listed once each/'; pt_rs 's/builds-on: S02 S03/builds-on: S07 S03/; s/builds-on: S02 |/builds-on: S07 |/'
D=$(chg other 'S02 planned again as S07' step:S02 'S07 goes out instead'); [ -n "$D" ] || fail 'no decision for the change'
rd next; ok "^withdrawn $N2\$"; N7=$(awk '$1 == "published" && / step=S07 / { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N7" ] || fail "S07's ticket was not published: $(cat "$T/out")"
c=$(grep -rl "^vid: withdrawn by plan change $D" "$T/gh/prs/$P2/comments" 2>/dev/null | head -n 1); [ -n "$c" ] || fail "#$N2's pull request has no comment naming the plan change"
grep -q "^- ROW-001 (.*): to step S07" "$c" || fail "the pull request's comment does not say ROW-001 went to S07: $(cat "$c")"
[ "$(grep -rl '^vid: withdrawn' "$T/gh/prs/$P2/comments" | grep -c .)" = 1 ] || fail 'the pull request was told more than once'
# a later ask there is never decided, nor recorded
k=$(ls "$T/gh/prs/$P2/comments" | grep -c .); H2b=$(head_ tk2); h2b=$(printf %s "$H2b" | cut -c1-12); ask "$P2" ROW-001 "$H2b"; rd step; no "^decided $P2 "
[ "$(ls "$T/gh/prs/$P2/comments" | grep -c .)" = $((k + 1)) ] || fail "a withdrawn ticket's pull request got another comment"; ! ls .vid/decide/pr-$P2-$h2b.* > /dev/null 2>&1 || fail "a decision was recorded for #$N2's pull request"
# S07's ticket, the step's first, names the withdrawn one and keeps its T5 and its title
F7=.vid/tw/out/issue-$N7.md; grep -qx -- "- earlier work: ticket #$N2, pull request #$P2" "$F7" || fail "S07's ticket does not name #$N2 and its pull request"
sed -n 1p "$F7" | grep -q '^# Step ticket S07: ' && grep -q '^- T5 (GR, SR)' "$F7" && ! grep -q '^- follows:' "$F7" || fail "S07's ticket lost its T5 or its title"
# a split takes HOS-005 out of S03's ticket, its pull request open: S03's amended, S06's names it, S03's pull request still decided
N3=$(awk '$1 == "published" && / step=S03 / { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N3" ] || { tw_start S03 && tw_post step S03 && N3=$TW_N; } || fail "S03's ticket failed"
H3=$(head_ tk3); P3=$(gh pr create -R $R --head tk3 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$N3")" | sed 's/.*\///'); gh pr ready "$P3" -R $R; ask "$P3" ROW-006 "$H3"; rd step; ok "^decided $P3 "
pt_rs 's/^\(step S03 .*\) HOS-005 |/\1 |/'; pt_rs 's/^shared: web$/step S06 | name: the second protection | modules: web mail | builds-on: S01 | rows: HOS-005 | lane: devagent\nshared: web/'
chg split 'HOS-005 goes alone' step:S03 'S03 ships without it' > /dev/null; tw_start S06 || { cat "$T/start" >&2; fail 'S06 was refused'; }
rd next; ok "^amended $N3\$"; N6=$(awk '$1 == "published" && / step=S06 / { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N6" ] || fail "S06's ticket was not published: $(cat "$T/out")"
F6=.vid/tw/out/issue-$N6.md; grep -qx -- "- earlier work: ticket #$N3, pull request #$P3" "$F6" || fail "S06's ticket does not name #$N3 and its pull request"
H3b=$(head_ tk3); ask "$P3" ROW-006 "$H3b"; rd step; ok "^decided $P3 "
# two open tickets, each with a pull request, swap a row (ROW-006 into S07's older #N7, ROW-005 into S03's #N3): at that same
# next each names the other and its pull request, whatever the order they are written in
[ "$N7" -lt "$N3" ] || fail "S07's ticket #$N7 is not older than S03's #$N3"; head_ tk7 > /dev/null; P7=$(gh pr create -R $R --head tk7 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$N7")" | sed 's/.*\///')
pt_rs 's/^\(step S03 .*rows: \)ROW-006 /\1ROW-005 /'; pt_rs 's/^\(step S07 .*rows: ROW-001\) ROW-005 /\1 ROW-006 /'; chg rows 'ROW-006 and ROW-005 change places' step:S03 'each step builds the other row' > /dev/null
rd next; ok "^amended $N7\$"; ok "^amended $N3\$"; grep -qx -- "- earlier work: ticket #$N3, pull request #$P3" ".vid/tw/out/issue-$N7.md" || fail "S07's ticket #$N7 does not name #$N3, which it took ROW-006 from"
grep -qx -- "- earlier work: ticket #$N7, pull request #$P7" ".vid/tw/out/issue-$N3.md" || fail "S03's ticket #$N3 does not name #$N7, which it took ROW-005 from"
# the line is no refusal on a fix ticket: the check refuses the same with it and without it
sed 's/^- kind: step$/- kind: fix/' "$F6" > "$T/f1.md"; grep -vx -- "- earlier work: ticket #$N3, pull request #$P3" "$T/f1.md" > "$T/f0.md"
sh "$CHECKS/writer.sh" check "$T/f1.md" | sed 's/ — .*md$//; s/line [0-9]*/line/' > "$T/c1" || true; sh "$CHECKS/writer.sh" check "$T/f0.md" | sed 's/ — .*md$//; s/line [0-9]*/line/' > "$T/c0" || true
cmp -s "$T/c1" "$T/c0" || fail "the earlier work line is refused on a fix ticket: $(diff "$T/c0" "$T/c1")"
exit 0
