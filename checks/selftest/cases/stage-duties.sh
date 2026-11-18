#!/bin/sh
# Purpose: selftest case — every okay names the dev side's duties and every passed report answers them (0.26.11.1.1, R3), checks/close.sh,
# results.sh and queue.sh on the writer's toy and the fake gh. A candidate of stage 1 is planted with its C3 passed. The staging okay
# carries the hosting quote (the ARCHITECTURE.md block, `> <key>: <value>` lines) and its six duties, holds no version, check name or
# refusal; a passed D1 with no duties.txt is not read; one missing a duty is refused with the duty named, posted back; the next with
# that duty `not done` refused again with the duty and the dev side's words, and the second refusal a Q line whose answers name
# `known`; `known` by RM refused, by the owner recorded with who and when, and the same report then read; a `not needed` duty said
# once, with its words, beside `d1 <N> passed`. The production okay carries the quote and its seven duties; a D2 with a duty
# `not done` and one with no line is read, never refused, each a Q line, as is each of a D2 with no duties.txt; two duties not done in
# one D1 report are two Q lines, known on one leaving the other (`production duty <duty>: <words, or not answered>`); `known`
# the owner's alone; a later production report saying the duty done settles its line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-duties: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
# dp <okay> <k> <report.txt> <steps> [<staging.txt>] [<duties.txt>]: a deploy report
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf '%s\ndecisions: none' "$3")"; P=''; for x in $4; do P="$P $x=pass"; done; rr_put "$Q" deploy.xml "$(rr_cases $P)"
  [ -z "${5:-}" ] || rr_put "$Q" staging.txt "$5"; [ -z "${6:-}" ] || rr_put "$Q" duties.txt "$6"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'closed S01'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
SD1=log-in; for d in environments outside-services sending-domain deploy-notes captures; do SD1="$SD1 $d"; done
PD1=service-switch-on; for d in backups point-in-time-recovery storage-versioning dns https monitoring; do PD1="$PD1 $d"; done
dl() { for d in $1; do case " $2 " in *" $d "*) ;; *) printf '%s: done — set on the host\n' "$d" ;; esac; done; }   # dl <duties> <left out>: each done
ST=$(printf 'staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none\nseed: synthetic')
# the staging okay: the hosting quote and the six duties, in plain words
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$O/body
grep -qx 'The hosting:' "$B" && grep -qx '> platform: one small hosting platform' "$B" && grep -qx "> staging: the platform's own address" "$B" || fail "the okay's hosting quote: $(cat "$B")"
grep -qx 'Duties:' "$B" || fail "the okay has no Duties: paragraph: $(cat "$B")"; for d in $SD1; do grep -q "^- $d: [a-z]" "$B" || fail "the staging okay lacks the duty $d"; done
for d in backups dns monitoring; do ! grep -q "^- $d: " "$B" || fail "the staging okay names the production duty $d"; done
! grep -nE '\.sh\b|[0-9]+\.[0-9]+\.[0-9]+|[Rr]efus|\.vid/' "$B" > "$T/out" || fail "the okay holds an internal word"
grep -q 'duties.txt' "$B" || fail 'the okay does not ask for duties.txt'
# a passed D1 with no duties.txt is not read
dp "$O" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")" build "$ST"; fetch; sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok "^d1${TAB}refused${TAB}1${TAB}a passed deploy has no duties.txt\$"
# one missing a duty: refused with the duty named, posted back
dp "$O" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")" build "$ST" "$(dl "$SD1" captures)"; fetch; cs decide --stage 1; ok '^d1-refused 1 1$'
grep -q 'duties.txt has no line for the duty captures' "$T/gh/issues/$O/comments/1" || fail "the refusal does not name the duty: $(cat "$T/gh/issues/$O/comments/1")"
# the next with it not done: refused again, the second a Q line answered again or known
dp "$O" 2 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")" build "$ST" "$(dl "$SD1" 'captures sending-domain deploy-notes'; printf 'deploy-notes: not done — the notes come with the first deploy\ncaptures: not done — the staging run has not answered yet\nsending-domain: not needed — the product sends no email\n')"; fetch
sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok "^d1${TAB}refused${TAB}2${TAB}the duty deploy-notes is not done: the notes come with the first deploy\$"
cs decide --stage 1; ok '^d1-item 1 notdone deploy-notes the duty deploy-notes is not done: the notes come with the first deploy'
# 0.26.11.1.1 (R3): two duties not done in one report; known on the first leaves the second its own Q line
QN0=$(qn 'the duty deploy-notes is not done'); [ -n "$QN0" ] || fail "no Q line for deploy-notes: $(grep '^- Q' .vid/RUN-STATE.md)"
sh "$QS" answer "$QN0" known 'the notes come later' > "$T/out" 2>&1 || fail "the owner's known on deploy-notes was refused: $(cat "$T/out")"
cs decide --stage 1; ok '^d1-item 1 notdone captures the duty captures is not done: the staging run has not answered yet'; no '^d1 1 passed'
QD=$(qn 'the duty captures is not done'); [ -n "$QD" ] || fail "the second duty not done hid behind the first's known: $(grep '^- Q' .vid/RUN-STATE.md)"
grep "^- $QD " .vid/RUN-STATE.md | grep -q 'again' && grep "^- $QD " .vid/RUN-STATE.md | grep -q 'known' || fail "the duty's Q line lacks again or known: $(grep "^- $QD " .vid/RUN-STATE.md)"
# known: the owner's alone, recorded with who and when; the same report then read, its not-needed duty said once with its words
! sh "$QS" answer "$QD" --by RM known 'a limit for now' > "$T/out" 2>&1 || fail 'RM ruled a duty known'
! sh "$QS" answer "$QD" --by delegate known 'a limit for now' > "$T/out" 2>&1 || fail 'a delegate ruled a duty known'
[ "$(grep -c . .vid/decide/duties-known)" = 1 ] || fail 'a refused known was recorded'
sh "$QS" answer "$QD" known 'captures come with the first staging run' > "$T/out" 2>&1 || fail "the owner's known was refused: $(cat "$T/out")"
grep -q "^captures${TAB}captures come with the first staging run${TAB}owner${TAB}20[0-9-]*T" .vid/decide/duties-known || fail "the known duty's record: $(cat .vid/decide/duties-known 2>/dev/null)"
cs decide --stage 1; ok '^d1 1 passed$'; ok '^not-needed d1 1: sending-domain — the product sends no email$'
cs decide --stage 1; no '^not-needed'; no '^d1 1 passed'
# the production okay: the quote and the seven duties
RH=.vid/decide/stage/1/1/rh; mkdir -p $RH .vid/decide/stage/1/1/cs .vid/decide/stage/1/1/cr; : > .vid/decide/stage/1/1/cs/passed; : > .vid/decide/stage/1/1/cs/done; : > .vid/decide/stage/1/1/cr/passed
printf 'issue\t90\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > $RH/ask; : > $RH/passed; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
mkdir -p .vid/decide/queue; printf '2026-11-09T13:00:00Z\tproduction:1:1:90\tyes\tdeploy it\towner\tapproved\n' >> .vid/decide/queue/answers; echo yes > .vid/decide/queue/offer
cs okay --production 1; ok '^asked [0-9]* okay production-1$'; P2=$(sed -n 's/^asked \([0-9]*\) okay production-1$/\1/p' "$T/out"); B=$T/gh/issues/$P2/body
grep -qx 'okay: production' "$B" && grep -qx "commit: $X" "$B" && grep -qx 'The hosting:' "$B" && grep -qx '> platform: one small hosting platform' "$B" && grep -qx 'Duties:' "$B" || fail "the production okay: $(cat "$B")"
for d in $PD1; do grep -q "^- $d: [a-z]" "$B" || fail "the production okay lacks the duty $d"; done; ! grep -q '^- captures: ' "$B" || fail 'the production okay names a staging duty'
! grep -nE '\.sh\b|[0-9]+\.[0-9]+\.[0-9]+|[Rr]efus|\.vid/' "$B" > "$T/out" || fail "the production okay holds an internal word"
# a D2 with dns not done and https unanswered: read, never refused, each a Q line; storage-versioning not needed, said once
PR=$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201\nlogs: the host'"'"'s log page' "$X")
dp "$P2" 1 "$PR" 'backup deploy' '' "$(dl "$PD1" 'dns https storage-versioning'; printf 'dns: not done — the domain is not bought yet\nstorage-versioning: not needed — the product stores no files\n')"; fetch
sh "$RS" deploy --stage 1 --kind d2 > "$T/out" 2>&1; ok "^d2${TAB}passed${TAB}1\$"
cs decide --stage 1; ok '^d2 1 passed$'; ok '^production-duty 1 dns: the domain is not bought yet$'; ok '^production-duty 1 https: not answered$'; ok '^not-needed d2 1: storage-versioning — the product stores no files$'
QN=$(qn 'production duty dns: the domain is not bought yet'); QH=$(qn 'production duty https: not answered'); [ -n "$QN" ] && [ -n "$QH" ] || fail "no production duty Q lines: $(grep '^- Q' .vid/RUN-STATE.md)"
! sh "$QS" answer "$QN" --by RM known 'later' > "$T/out" 2>&1 || fail 'RM ruled a production duty known'
sh "$QS" answer "$QN" known 'the domain comes next month' > "$T/out" 2>&1 || fail "the owner's known was refused: $(cat "$T/out")"; sh "$QS" sync > /dev/null 2>&1
! grep -q "^- $QN " .vid/RUN-STATE.md || fail 'the known production duty is still a Q line'; grep -q "^- $QH " .vid/RUN-STATE.md || fail 'the https line went with the dns answer'
# a later production report saying https done settles its line
K2=.vid/decide/stage/1/2; mkdir -p $K2/d2; cp $K/ask $K/commit $K2/; : > $K2/named; : > $K2/passed; I2=$(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); gh issue create -R $R --title 'Okay: production again' --body b --label deploy > /dev/null
printf 'issue\t%s\ncommit\t%s\nasked\t2099-01-01T00:00:00Z\n' "$I2" "$X" > $K2/d2/ask
dp "$I2" 1 "$PR" 'backup deploy' '' "$(dl "$PD1" dns; printf 'dns: not done — still not bought\n')"; fetch; cs decide --stage 1; ok '^d2 1 passed$'; no '^production-duty 1 https'
sh "$QS" sync > /dev/null 2>&1; ! grep -q "^- $QH " .vid/RUN-STATE.md || fail 'a later report saying https done did not settle its line'
# 0.26.11.1.1 (R3): a passed D2 with no duties.txt: read, and every production duty its own Q line, not answered
K3=.vid/decide/stage/1/3; mkdir -p $K3/d2; cp $K/ask $K/commit $K3/; : > $K3/named; : > $K3/passed; I3=$(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); gh issue create -R $R --title 'Okay: production, a third' --body b --label deploy > /dev/null
printf 'issue\t%s\ncommit\t%s\nasked\t2099-02-01T00:00:00Z\n' "$I3" "$X" > $K3/d2/ask
dp "$I3" 1 "$PR" 'backup deploy'; fetch; cs decide --stage 1; ok '^d2 1 passed$'; for d in $PD1; do ok "^production-duty 1 $d: not answered\$"; done
sh "$QS" keys > "$T/out" 2>&1; [ "$(grep -c "^pduty:$I3:" "$T/out")" = 7 ] || fail "not seven Q lines for a D2 with no duties.txt: $(grep '^pduty:' "$T/out")"
exit 0
