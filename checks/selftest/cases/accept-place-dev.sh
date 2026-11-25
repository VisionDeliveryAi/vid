#!/bin/sh
# Purpose: selftest case — the step of an outside service the developers can reach (`place: dev`) is accepted with its passing
# case, and never without (FB-4 A2, checks/decide.sh through round.sh, close.sh). In GitHub manual (fixtures/accept.sh), a
# ticket of ROW-019 and SEAM-003, each row's marks the planner's: SEAM-003's case erring `setup:`, the ticket is not accepted and
# its row never passed: its test could not run; passing at the next commit, the ticket is accepted and SEAM-003 with it. In
# GitHub auto (fixtures/tw-toy.sh), the ticket merged, stage 1's staging okay lists SEAM-001, never SEAM-003, the staging run
# leaves it out, and the close's conditions never wait for it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/manual; mkdir "$T"
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-place-dev: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
SM='seam | SEAM-003 | the synonym service | looking up the other names of an occupation | chosen: D-003 | credentials: held | probe: owed | evidence: owed | quirks: none yet | place: dev'
mk() { _m=$(sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' -v r="$1" '$1 == r { print $7 }'); echo "${_m:-none}"; }
# GitHub manual
ac_project "$T/p" || fail 'the toy could not be made'
pt_after SEAM-002 "$SM"; git commit -qam 'a service the developers reach'; git rev-parse HEAD > .vid/tw/applied
AC_N=$(gh_issue 'Step S06'); { mn_ticket "$AC_N" S06 step ROW-019 SEAM-003 | sed "s/^- SEAM-003 marks: .*/- SEAM-003 marks: $(mk SEAM-003)/"; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"
printf 'published %s kind=step step=S06 rows=ROW-019,SEAM-003 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log
at() { ac_head "$AC_C" 1 "$@"; ac_grade "$AC_C" 'ROW-019 kept — seen' 'SEAM-003 kept — seen'; ac_round accept "$AC_N" "$AC_C"; }
at ROW-019=pass 'SEAM-003=err:setup:_no_credentials_here'
! grep -q "^accepted #$AC_N " "$T/out" || fail 'the ticket is accepted with SEAM-003 not run'
ac_last | grep 'SEAM-003' | grep -q 'its test could not run' || { ac_last > "$T/out"; fail 'that its test could not run is not said'; }
! grep -qE '^row SEAM-003 (accepted|owed|paid)' .vid/tw/handed 2>/dev/null || fail "SEAM-003 that could not run is recorded: $(grep SEAM-003 .vid/tw/handed)"
tk_dev 'again'; AC_C=$(git -C "$T/dev" rev-parse HEAD); at ROW-019=pass SEAM-003=pass
grep -q "^accepted #$AC_N " "$T/out" || { ac_last >> "$T/out"; fail 'the ticket is not accepted with SEAM-003 passing'; }
grep -q '^row SEAM-003 accepted' .vid/tw/handed || fail "SEAM-003 is not accepted with its step: $(grep SEAM-003 .vid/tw/handed)"
# GitHub auto: the closes
unset CLAUDE_CODE_SESSION_ID; T=$T0/auto; mkdir "$T"; cd "$T"; . "$CHECKS/selftest/fixtures/tw-toy.sh"; CS=$CHECKS/close.sh; GS=$CHECKS/github.sh; R=owner/code
tw_toy "$T/toy"; pt_after SEAM-002 "$SM"; pt_rs 's/\(rows: ROW-006 [^|]*HOS-005\) |/\1 SEAM-003 |/; s/^\(needs ROW-006 [^|]*HOS-005\) | -$/\1 SEAM-003 | -/'
g add -A; g commit -qm 'a service the developers reach'; pt_record; tw_ratify 'Yes, publish it' || fail 'the plan was not ratified again'
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
tk() { _n=$1; _k=$2; _s=$3; shift 3; { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$_n" "$_k"; for r; do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(mk "$r")"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$_n.md"; gh issue create -R $R --title "t$_n" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$_n" "$_k" "$_s" "$(echo "$*" | tr ' ' ,)" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003 ROW-004; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'row ROW-004 accepted'; tw_hand 'closed S01'
tk 3 step S03 SEAM-001 SEAM-003; mg 21 3; tw_hand 'row SEAM-001 owed'; tw_hand 'row SEAM-003 accepted'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
sh "$CS" conds 1 > "$T/out" 2>&1 || :; grep -q '^1 SEAM-001 owed, not paid$' "$T/out" && ! grep -q 'SEAM-003' "$T/out" || fail 'the close of stage 1 waits for SEAM-003'
sh "$CS" okay --stage 1 > "$T/out" 2>&1 || fail 'the okay was not asked'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
grep -qx 'outside-service rows: SEAM-001' "$T/gh/issues/$O/body" || { cat "$T/gh/issues/$O/body" > "$T/out"; fail 'the okay lists SEAM-003'; }
mkdir -p $K/d1; : > $K/d1/passed; printf 'staging\thttp://127.0.0.1:5001\nseam\tSEAM-001\treal\n' > $K/d1/read
sh "$CS" ask --cs 1 > "$T/out" 2>&1 || fail 'CS was not asked'; N=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); grep -q 'SEAM-001' "$T/gh/issues/$N/body" && ! grep -q 'SEAM-003' "$T/gh/issues/$N/body" || { cat "$T/gh/issues/$N/body" > "$T/out"; fail 'the staging run asks SEAM-003'; }
exit 0
