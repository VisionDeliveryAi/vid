#!/bin/sh
# Purpose: selftest case — a close chunk lost the same way twice at its commit (0.26.10.28.10, R2), checks/close.sh and checks/queue.sh
# on the toy and the fake gh. A chunk whose rows could not run is asked again once, bare. Lost again with the same rows unrun in the
# same engines (their messages may differ), the owner's item says it read the same; a bare again is refused (GM-4 K6: every owner's
# answer carries the owner's words);
# an again with words is posted with them, `why: <words>`, so the dev side knows what must change. A later loss that reads otherwise is
# no longer the same, and the chunk reported whole closes the step. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "close-lost-same: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; R=owner/code; mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); printf 'close-chunk-minutes: 1\nclose-wait-minutes: 99\n' >> .vid/tw/settings
printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n> ROW-004 | journey | j | b | n/a | x transitions: 1. a 2. b | REQ-001 | o\n- ROW-004 marks: journey\n\n## Regression rows\n\n- ROW-001\n' > .vid/tw/out/issue-1.md
printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; echo 2 > .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" > .vid/decide/merges
printf 'engines alpha beta | stand-in: results reader\n' >> .vid/tw/handed
cs ask S01; [ "$RC" = 0 ] || fail 'the ask failed'; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out"); [ -n "$N" ] || fail 'no ask'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; E=$2; shift 2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$M")"; rr_put "$Q" cases-$E.xml "$(rr_cases "$@")"; send "$Q"; }
rqx() { Q=req-$N-$1; E=$2; shift 2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' 0000000000000000000000000000000000000000)"; rr_put "$Q" cases-$E.xml "$(rr_cases "$@")"; send "$Q"; }   # refused: another commit
cm() { printf '%s\nby: DM\n' "$1" > "$T/c"; gh issue comment "$N" -R $R --body-file "$T/c" > /dev/null; }
rd() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; cs decide S01; [ "$RC" = 0 ] || fail "decide failed: $RC"; }
lastagain() { for f in $(ls "$T/gh/issues/$N/comments/" | sort -n); do grep -q '^vid: again p2c1$' "$T/gh/issues/$N/comments/$f" && L=$f; done; cat "$T/gh/issues/$N/comments/$L"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*chunk ${1:-p2c1}, lost twice.*/\1/p" .vid/RUN-STATE.md | tail -n 1; }
for c in $(sed -n 's/^- chunk \(p1c[0-9]*\), .*/\1/p' "$T/gh/issues/$N/body"); do rq "$c-1" alpha ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; done
# two refused reports of p2c2, whatever their reasons, are never the same: a bare again goes
rqx p2c2-1 beta ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; cm 'vid: lost p2c2 0'; rd; ok '^close-again S01 p2c2$'
rqx p2c2-2 beta ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; cm 'vid: lost p2c2 1'; rd; ok '^close-lost S01 p2c2$'
Q2=$(qn p2c2); [ -n "$Q2" ] || fail 'no Q line for p2c2'; ! grep "^- $Q2 · " .vid/RUN-STATE.md | grep -q 'the same as the attempt before' || fail 'two refused reports are called the same'
sh "$QS" answer "$Q2" again 'run it again' > "$T/out" 2>&1 || fail "an again was refused after two refused reports: $(cat "$T/out")"
rq p2c2-3 beta ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass
# attempt 1: ROW-003 and ROW-004's first transition could not run in beta: asked again once, bare
rq p2c1-1 beta 'ROW-003=err:setup: only alpha maps board-1a2b.test' 'ROW-004-T1=err:setup: no mail fake' ROW-004-T2=pass ROW-001=pass; rd; ok '^close-again S01 p2c1$'
lastagain > "$T/a1"; ! grep -q '^why:' "$T/a1" || fail "the close's own again carries words: $(cat "$T/a1")"
# attempt 2, the same rows unrun the same way, another message: the owner's item says it read the same
rq p2c1-2 beta 'ROW-003=err:setup: only alpha maps board-9f8e.test' 'ROW-004-T1=err:setup: no mail fake' ROW-004-T2=pass ROW-001=pass; rd; ok '^close-lost S01 p2c1$'
QN=$(qn); [ -n "$QN" ] || fail "no Q line for the lost chunk: $(grep '^- Q' .vid/RUN-STATE.md)"
grep "^- $QN · " .vid/RUN-STATE.md | grep -q 'the same as the attempt before' || fail "the Q line does not say it read the same: $(grep "^- $QN · " .vid/RUN-STATE.md)"
# a bare again is refused (GM-4 K6: every owner's answer carries the owner's words); an again with words is posted with them
RC=0; sh "$QS" answer "$QN" again > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a bare again was taken for a chunk that read the same'; ok "needs the owner's words"
sh "$QS" answer "$QN" again 'map the board domains in beta first' > "$T/out" 2>&1 || fail "the again with words was refused: $(cat "$T/out")"
rd; ok '^close-again S01 p2c1$'; lastagain > "$T/a2"; grep -qx 'why: map the board domains in beta first' "$T/a2" || fail "the again carries no words: $(cat "$T/a2")"
# lost again with no new attempt, said on the issue: the pair already answered is not the same again
cm 'vid: lost p2c1 2'; rd; ok '^close-lost S01 p2c1$'; QN=$(qn); ! grep "^- $QN · " .vid/RUN-STATE.md | grep -q 'the same as the attempt before' || fail 'a loss with no new attempt is called the same again'
sh "$QS" answer "$QN" again 'once more' > "$T/out" 2>&1 || fail "the again was refused: $(cat "$T/out")"; rd; ok '^close-again S01 p2c1$'
# attempt 3 reads otherwise (fewer rows unrun, as attempts add up): its item is not the same, and an again goes
rq p2c1-3 beta 'ROW-003=err:setup: only alpha maps board-77aa.test' ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; rd; ok '^close-lost S01 p2c1$'
QN=$(qn); ! grep "^- $QN · " .vid/RUN-STATE.md | grep -q 'the same as the attempt before' || fail 'a loss that read otherwise is called the same'
sh "$QS" answer "$QN" again 'try it again' > "$T/out" 2>&1 || fail "an again was refused for a loss that read otherwise: $(cat "$T/out")"; rd; ok '^close-again S01 p2c1$'
# reported whole: closed
rq p2c1-4 beta ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-001=pass; rd; ok '^closed S01$'
echo 'close-lost-same: ok'
