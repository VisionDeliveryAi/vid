#!/bin/sh
# Purpose: selftest case — the owner may ask for production data on staging (0.26.11.1.1, R6), checks/queue.sh, close.sh, results.sh
# and walk.sh on the writer's toy and the fake gh. `control seed` takes the owner's word alone (no --by, no other word than production
# or synthetic), recorded with who and when; production is refused before a production deploy has passed, with "there is no
# production data yet". Once production exists and the owner says production, the staging okay says `seed: production` and its
# sentence; a passed D1 whose staging.txt says another seed, or none, is refused; one saying production is read, and the walk brief of
# its staging says it holds real people's data and that the walker sends nothing to anyone. The owner's synthetic again: the next
# okay says `seed: synthetic`, without the sentence. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-seed-production: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; WS=$CHECKS/walk.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r" "$T/wk"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases seed=pass migrate=pass deploy=pass ready=pass)"; rr_put "$Q" staging.txt "$3"; rr_put "$Q" duties.txt "$DU"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'closed S01'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main)
# the owner's word alone, and production only once production exists
qs control seed production 'use production data on staging'; [ "$RC" != 0 ] && grep -q 'there is no production data yet' "$T/out" || fail "production was taken before any production: $(cat "$T/out")"
qs control seed --by RM synthetic 'for the owner'; [ "$RC" != 0 ] || fail 'control seed took --by RM'
qs control seed --by delegate synthetic 'for the owner'; [ "$RC" != 0 ] || fail 'control seed took --by delegate'
qs control seed sample 'some data'; [ "$RC" != 0 ] || fail 'control seed took a word other than production or synthetic'
! grep -q "${TAB}control:seed${TAB}" .vid/decide/queue/answers 2>/dev/null || fail 'a refused seed word was recorded'
printf '%s\tD2 #0\t2026-11-01T00:00:00Z\n' "$X" > .vid/decide/production   # a production deploy has passed
qs control seed production 'use production data on staging'; [ "$RC" = 0 ] || fail "the owner's production word was refused: $(cat "$T/out")"
grep -q "${TAB}control:seed${TAB}production${TAB}use production data on staging${TAB}owner${TAB}" .vid/decide/queue/answers || fail "the seed word's record: $(cat .vid/decide/queue/answers)"
# the staging okay: seed: production and its sentence
K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$O/body
grep -qx 'seed: production' "$B" && ! grep -qx 'seed: synthetic' "$B" || fail "the okay's seed: $(head -n 4 "$B")"
grep -qF "Load a copy of production's newest backup into staging in place of the made-up data, before the migration. It holds real customers' data: keep every outside service on staging limited, so nothing reaches a real person." "$B" || fail "the okay lacks the sentence: $(cat "$B")"
# a D1 with another seed, or none: refused; production: read
ST='staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none'
dp "$O" 1 "$(printf "$ST\nseed: synthetic")"; fetch; sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok "^d1${TAB}refused${TAB}1${TAB}staging.txt says seed: synthetic, where the okay says seed: production\$"
dp "$O" 1 "$(printf "$ST")"; fetch; sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok "^d1${TAB}refused${TAB}1${TAB}staging.txt has no seed: line\$"
dp "$O" 1 "$(printf "$ST\nseed: production")"; fetch; cs decide --stage 1; ok '^d1 1 passed$'
# the walk brief of a staging on production data
mkdir -p $K/cs; printf 'issue\t50\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > $K/cs/ask; : > $K/cs/passed; : > $K/cs/done
VID_WALK_TMP=$T/wk; export VID_WALK_TMP; RC=0; sh "$WS" brief --stage 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "no brief: $(cat "$T/out")"
BR=$(tail -n 1 "$T/out")/brief.md; grep -q "real people's data" "$BR" && grep -q 'send nothing to anyone' "$BR" || fail "the walk brief lacks its sentence: $(cat "$BR")"
# the owner's synthetic again: the next okay says synthetic, no sentence
qs control seed synthetic 'made-up data on staging again'; [ "$RC" = 0 ] || fail "the owner's synthetic word was refused: $(cat "$T/out")"
mkdir -p $K/w1; : > $K/w1/done; K2=.vid/decide/stage/2/1; mkdir -p $K2; cp $K/ask $K/commit $K2/; : > $K2/named; : > $K2/passed
cs okay --stage 2; ok '^asked [0-9]* okay stage-2$'; O2=$(sed -n 's/^asked \([0-9]*\) okay stage-2$/\1/p' "$T/out"); B=$T/gh/issues/$O2/body
grep -qx 'seed: synthetic' "$B" && ! grep -q 'Load a copy of production' "$B" || fail "the okay after synthetic: $(cat "$B")"
exit 0
