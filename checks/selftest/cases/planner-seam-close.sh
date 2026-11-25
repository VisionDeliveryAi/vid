#!/bin/sh
# Purpose: selftest case — the closes ask and wait for an outside service with its step's stage (FB-4 A2, checks/close.sh and
# queue.sh), on the writer's toy (fixtures/tw-toy.sh) with SEAM-003 added to S05, the stage 2 step. With S03's ticket (SEAM-001)
# and S05's (SEAM-003) both merged, stage 1's staging okay lists SEAM-001 alone, its close conditions never name SEAM-003 and the
# status counts the test-site rows of stage 1 without it; stage 2's okay lists both. Stage 1's close waits for SEAM-001 and
# the gate 2 row of its steps, never for its gate 1 and gate 3 rows; nor does the project's end. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "planner-seam-close: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
# SEAM-003 in S05 (stage 2), SEAM-002 in S02 (stage 1), the plan recorded and ratified again
pt_after SEAM-002 'seam | SEAM-003 | the synonym service | looking up the other names of an occupation | chosen: D-003 | credentials: not-yet | probe: unreachable-risk(credentials not-yet) | evidence: owed | quirks: none yet'
pt_rs 's/rows: ROW-017 |/rows: ROW-017 SEAM-003 |/; s/^needs ROW-017 | -$/needs ROW-017 SEAM-003 | -/'
g add -A; g commit -qm 'a third outside service'; pt_record; tw_ratify 'Yes, publish it' || fail 'the plan was not ratified again'
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
# mg <pull request> <ticket>: merged, every ticket at the one commit the candidate is
( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m m && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main)
mg() { echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003,ROW-004 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'row ROW-004 accepted'; tw_hand 'closed S01'
tk 3 step S03 SEAM-001,ROW-010 'SEAM-001=seam ROW-010=owed-staging'; mg 21 3; tw_hand 'row SEAM-001 owed'; tw_hand 'row ROW-010 owed'
tk 4 step S05 ROW-017,SEAM-003 'SEAM-003=seam'; mg 22 4; tw_hand 'row SEAM-003 owed'; tw_hand 'row ROW-017 accepted'
tk 5 step S04 ROW-009,ROW-011 'ROW-009=owed-rehearsal ROW-011=owed-production'; mg 23 5; tw_hand 'row ROW-009 owed'; tw_hand 'row ROW-011 owed'
sh "$GS" tw-sync > /dev/null 2>&1; X=$(git --git-dir="$T/code.git" rev-parse main)
cand() { K=.vid/decide/stage/$1/1; mkdir -p "$K"; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$K/ask"; echo "$X" > "$K/commit"; : > "$K/named"; : > "$K/passed"; }
cand 1
# stage 1's close: the gate 2 row and the seam of its steps, never the gate 1 and 3 rows, nor SEAM-003
cs conds 1; ok '^1 SEAM-001 owed, not paid$'; ok '^1 ROW-010 owed, not paid$'; no 'ROW-009'; no 'ROW-011'; no 'SEAM-003'
cs endconds; ok '^2 SEAM-003 owed, not paid$'; no '^2 ROW-009 '; no '^2 ROW-011 '
# the status: the test-site rows of stages 0 and 1, SEAM-003 not among them
N=$(sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$1 != "SEAM-003" && $5 ~ /^[01]$/ && $7 ~ /(^| )(owed-staging|seam)( |$)/ { n++ } END { print n + 0 }')
sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail 'status failed'; ok "^stage 1: .* paid 0 of $N\( \|\$\)"
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
grep -qx 'outside-service rows: SEAM-001' "$T/gh/issues/$O/body" || fail "stage 1's okay: $(grep '^outside-service' "$T/gh/issues/$O/body")"
# stage 2's candidate: both
mv .vid/decide/stage/1 "$T/s1"; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"; cand 2
cs okay --stage 2; ok '^asked [0-9]* okay stage-2$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-2$/\1/p' "$T/out")
grep -qx 'outside-service rows: SEAM-001 SEAM-003' "$T/gh/issues/$O/body" || fail "stage 2's okay: $(grep '^outside-service' "$T/gh/issues/$O/body")"
exit 0
