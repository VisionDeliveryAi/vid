#!/bin/sh
# Purpose: selftest case — a lost close chunk said on the issue (v0.26.10.28.2, R2, F-012), checks/close.sh on the toy and the fake gh, the quiet time
# at 99 minutes so nothing goes by it. A chunk absent with no word waits. DevAgent's `vid: lost p2c2 0` brings `vid: again p2c2` at once; the same comment
# said again after that again changes nothing; `vid: lost p2c2 1` makes the owner's lost item at once. A loss older than the chunk's newest
# `vid: reported` comment changes nothing. The chunks reported, the close closes. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "close-lost-said: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); printf 'close-chunk-minutes: 1\nclose-wait-minutes: 99\n' >> .vid/tw/settings
printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n> ROW-004 | journey | j | b | n/a | x transitions: 1. a 2. b | REQ-001 | o\n- ROW-004 marks: journey\n\n## Regression rows\n\n- ROW-001\n' > .vid/tw/out/issue-1.md
printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; echo 2 > .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" > .vid/decide/merges
printf 'engines alpha beta | stand-in: results reader\n' >> .vid/tw/handed
cs ask S01; [ "$RC" = 0 ] || fail 'the ask failed'; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out"); [ -n "$N" ] || fail 'no ask'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; E=$2; shift 2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$M")"; rr_put "$Q" cases-$E.xml "$(rr_cases "$@")"; send "$Q"; }
cm() { printf '%s\nby: DM\n' "$1" > "$T/c"; gh issue comment "$N" -R $R --body-file "$T/c" > /dev/null; }
rd() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; cs decide S01; [ "$RC" = 0 ] || fail "decide failed: $RC"; }
agains() { grep -lx 'vid: again p2c2' "$T"/gh/issues/"$N"/comments/* 2>/dev/null | grep -c . || true; }
grep -q -- '- chunk p2c2, beta' "$T/gh/issues/$N/body" && grep -q -- '- chunk p2c1, beta' "$T/gh/issues/$N/body" || fail "the chunks: $(grep chunk "$T/gh/issues/$N/body")"
# phase 1 reported; p2c1 and p2c2 absent, inside the quiet time: they wait
for c in $(sed -n 's/^- chunk \(p1c[0-9]*\), .*/\1/p' "$T/gh/issues/$N/body"); do rq "$c-1" alpha ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; done
rd; no '^close-again'; no '^close-lost'
# the first loss said: asked again at once
cm 'vid: lost p2c2 0'; rd; ok '^close-again S01 p2c2$'; no 'close-again S01 p2c1'; [ "$(agains)" = 1 ] || fail "agains: $(agains)"
# the same loss said again, after that again: nothing
cm 'vid: lost p2c2 0'; rd; no '^close-again'; no '^close-lost'; [ "$(agains)" = 1 ] || fail 'a superseded loss was asked again'
# the second loss said: the owner's at once
cm 'vid: lost p2c2 1'; rd; ok '^close-lost S01 p2c2$'; grep -q '^lost p2c2' .vid/decide/close/S01/1/items || fail 'the second loss is no item'
# a loss older than the chunk's newest report comment: nothing
cm 'vid: lost p2c1 0'; cm 'vid: reported p2c1-1'; rd; no 'close-again S01 p2c1'; no 'close-lost S01 p2c1'
# reported, green: closed
for c in p2c1 p2c2; do rq "$c-1" beta ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; done; rd; ok '^closed S01$'
echo 'close-lost-said: ok'
