#!/bin/sh
# Purpose: selftest case — stage 0 always carries a real run of the walking skeleton (0.26.11.1.3, R3), checks/close.sh and results.sh on the
# writer's toy and the fake gh. Stage 0's candidate is planted with its C3 passed, the skeleton ticket merged. Its staging okay lists the
# `skeleton` line, the skeleton's journey end to end where the product's people run it, and asks its `real:` answer keyed by its own
# issue; a passed D1 with no `real:` line is refused and posted back, stage 0's close waiting on D1; the next attempt with none again is
# a Q line for the owner, whose known clears the missing answer, the same report then read, `missing` in its read; a later
# stage-0 candidate's okay lists the skeleton line again, and its attempt answered `done` is read, its real line in the read. Then, where skills/ and templates/ stand
# beside checks/, stage 0's card in vid-stage and in the STAGES template names the skeleton's real run. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "skeleton-real-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; RS=$CHECKS/results.sh; QS=$CHECKS/queue.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)
ST=$(printf 'staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none\nseed: synthetic')
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"
  rr_put "$Q" staging.txt "$(printf '%s\n%s' "$ST" "$3")"; rr_put "$Q" duties.txt "$DU"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-001 ''; mg 20 2; tw_hand 'row ROW-001 accepted'; tw_hand 'closed S01'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/0/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
SK="skeleton: the skeleton's journey, end to end, where the product's people run it (their kind of machine, or the hosted site), on the real outside services and a real sign-in"
# stage 0's okay lists the skeleton line and asks its real: answer
cs okay --stage 0; ok '^asked [0-9]* okay stage-0$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-0$/\1/p' "$T/out"); B=$T/gh/issues/$O/body
grep -qxF -- "- 1. $SK" "$B" || { cp "$B" "$T/out"; fail "stage 0's okay lacks the skeleton line"; }
grep -qF 'real: #<this issue>-<n> done — <what was run, where>' "$B" || { cp "$B" "$T/out"; fail "stage 0's okay does not ask the real: line"; }
grep -qxF "real${TAB}1${TAB}$SK" $K/d1/ask || { cp $K/d1/ask "$T/out"; fail "the okay's ask does not record the skeleton line"; }
# a passed D1 with no real: line: refused, posted back; stage 0's close waits on D1
dp "$O" 1 ''; fetch; sh "$RS" deploy --stage 0 > "$T/out" 2>&1; ok "^d1${TAB}refused${TAB}1${TAB}staging.txt has no real: line for #$O-1"
cs decide --stage 0; ok '^d1-refused 0 1$'; no '^d1 0 passed'; cs conds 0; ok '^2 D1 not passed'
# the next attempt, again with none: refused twice, a Q line; the owner's known clears the missing answer and the same report is read
dp "$O" 2 ''; fetch; cs decide --stage 0; ok "^d1-item 0 notreal 1 staging.txt has no real: line for #$O-1"; no '^d1 0 passed'
QR=$(qn "staging.txt has no real: line for #$O-1"); [ -n "$QR" ] || fail "no Q line for the missing real answer: $(grep '^- Q' .vid/RUN-STATE.md)"
sh "$QS" answer "$QR" known 'the hosted site comes with stage 1; run it there' > "$T/out" 2>&1 || fail "the owner's known was refused: $(cat "$T/out")"
cs decide --stage 0; ok '^d1 0 passed$'; grep -qxF "real${TAB}1${TAB}missing${TAB}" $K/d1/read || { cp $K/d1/read "$T/out"; fail 'the read does not say the ruled answer was missing'; }
cs conds 0; no 'D1 not passed'
# a later stage-0 candidate's okay lists the skeleton line again; its attempt answered done is read, the line in the read
K2=.vid/decide/stage/0/2; mkdir -p $K2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > $K2/ask; echo "$X" > $K2/commit; : > $K2/named; : > $K2/passed
cs okay --stage 0; ok '^asked [0-9]* okay stage-0$'; O2=$(sed -n 's/^asked \([0-9]*\) okay stage-0$/\1/p' "$T/out"); grep -qxF -- "- 1. $SK" "$T/gh/issues/$O2/body" || fail "a later stage-0 okay lacks the skeleton line"
dp "$O2" 1 "real: #$O2-1 done — the journey run end to end on the hosted site, signed in for real, the real mail read"; fetch
cs decide --stage 0; ok '^d1 0 passed$'; grep -qxF "real${TAB}1${TAB}done${TAB}the journey run end to end on the hosted site, signed in for real, the real mail read" $K2/d1/read || { cp $K2/d1/read "$T/out"; fail 'the read lacks the real line'; }
# stage 0's card names the skeleton's real run
VS=$CHECKS/../skills/vid-stage/SKILL.md; TS=$CHECKS/../templates/STAGES.md
[ -f "$VS" ] && [ -f "$TS" ] || { echo 'needs skills/vid-stage/SKILL.md and templates/STAGES.md for the card'; exit 77; }
awk '/^- \*\*Stage 0.s card\*\*/ { on = 1 } on { print } on && /holds none\./ { exit }' "$VS" | tr '\n' ' ' | tr -s ' ' | grep -q 'its journey runs once for real where' || fail "stage 0's card in vid-stage does not name the skeleton's real run"
grep '^- \*\*What proves it done:\*\* its rows pass' "$TS" | grep -q 'its journey runs once for real where' || fail "stage 0's card in the STAGES template does not name the skeleton's real run"
exit 0
