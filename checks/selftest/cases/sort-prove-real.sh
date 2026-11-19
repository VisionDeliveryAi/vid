#!/bin/sh
# Purpose: selftest case — a breach no test here can show goes to the staging okay, not into a note (0.26.11.1.3, R3), checks/results.sh,
# decide.sh, queue.sh and close.sh. Part 1, on the results reader's made-up reports: a sort holding `prove it real` is read, never
# refused, and gives `finding: real — <the line>`; the same tree with that line `note it` gives the same evidence but that one line, and
# the same ticket decision, word for word; the queue counts no finding for the real line. Part 2, on the writer's toy and the fake gh:
# stage 1's staging okay lists the open `finding: real` line of its ticket, numbered (a note line not), and asks a `real:` line for it
# keyed by its own issue; a passed D1 with no such line (one keyed to another okay answers nothing) is refused and posted back, and the
# stage's close waits on D1; the next, `not done`, is refused again and a Q line for the owner, which RM may not rule; the owner's
# known is recorded and the same report then read, its real line in the read; a later candidate's okay lists the line no more. Then,
# where devagent/ and docs/ stand beside checks/, SR's table has its one `prove it real` row and the format names the word. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT
fail() { echo "sort-prove-real: $*" >&2; cat "$T0/out" >&2 2>/dev/null; exit 1; }
TAB=$(printf '\t')
# --- part 1: the reader, the decision and the queue --------------------------------------------------------------------------
( T=$T0/one; mkdir -p "$T"
  . "$CHECKS/selftest/fixtures/tickets.sh"
  . "$CHECKS/selftest/fixtures/results-reports.sh"
  RS=$CHECKS/results.sh; DS=$CHECKS/decide.sh; QS=$CHECKS/queue.sh; rr_project; : > .vid/RUN-STATE.md; printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
  git init -q --bare "$T/code.git"; gh_fake; mv "$T/bin/gh" "$T/bin/gh-fake"
  cat > "$T/bin/gh" <<'G'
#!/bin/sh
case "$1 $2 ${7:-}" in 'pr view labels') cat "$FAKEGH/prs/$3/labels" 2>/dev/null | paste -sd , -; exit 0 ;; 'pr view body') printf 'ticket: #x\n\nDecisions: none\n'; exit 0 ;; esac
exec "$(dirname "$0")/gh-fake" "$@"
G
  chmod +x "$T/bin/gh"; for n in 1 2 3 5; do mkdir -p "$T/gh/issues/$n/comments"; echo OPEN > "$T/gh/issues/$n/state"; done; mkdir -p "$T/gh/prs/4/comments"
  H=$RR_H12; S=sort-pr-4-$H-1; mkdir -p .vid/round; printf 'open\t4\t3\t%s\tfalse\t\t1\t1\t2026-11-09T10:00:00Z\t\n' "$RR_H" > .vid/round/read
  # sorted <word>: SEAM-001's line sorted <word>, sent as the ticket's one sort report, then read and decided
  sorted() { rm -rf "$T/r/$S"; rr_put "$S" sorted.txt "$(printf 'by: SR\ncommit: %s\nSEAM-001 %s — only the real feed shows it — SEAM-001 unclear — which feed?\nROW-001 drop it — a drop — ROW-001 breached test — not in use' "$RR_H" "$1")"; rr_send "$S"
    sh "$RS" read --ticket 3 --pr 4 --head "$RR_H" > "$T0/ev-$2" 2>&1 || { cp "$T0/ev-$2" "$T0/out"; fail "the read failed with $1"; }
    sh "$DS" decide --ticket 3 --pr 4 --head "$RR_H" > "$T0/dec-$2" 2>&1 || { cp "$T0/dec-$2" "$T0/out"; fail "the decision failed with $1"; }
    sh "$QS" keys > "$T0/keys-$2" 2>&1 || { cp "$T0/keys-$2" "$T0/out"; fail "queue keys failed with $1"; }; }
  rr_good
  sorted 'note it' note
  RC=0; sh "$RS" check "$S" --ticket 3 > "$T0/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail 'the sort with note it was refused'
  sorted 'prove it real' real
  RC=0; sh "$RS" check "$S" --ticket 3 > "$T0/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && grep -qx "ok $S" "$T0/out" || fail 'a sort holding prove it real was refused'
  cp "$T0/ev-real" "$T0/out"; grep -qxF 'finding: real — only the real feed shows it — SEAM-001 unclear — which feed?' "$T0/ev-real" || fail 'no finding: real line for the prove it real line'
  ! grep -q '^finding: note' "$T0/ev-real" || fail 'the prove it real line was also read as a note'
  grep -qxF 'finding: note — only the real feed shows it — SEAM-001 unclear — which feed?' "$T0/ev-note" || { cp "$T0/ev-note" "$T0/out"; fail 'the note it tree has no finding: note line'; }
  sed 's/^finding: note — /finding: real — /' "$T0/ev-note" > "$T0/ev-note2"; cmp -s "$T0/ev-note2" "$T0/ev-real" || { diff "$T0/ev-note2" "$T0/ev-real" > "$T0/out" || true; fail 'the evidence differs beyond the finding line'; }
  cmp -s "$T0/dec-note" "$T0/dec-real" || { diff "$T0/dec-note" "$T0/dec-real" > "$T0/out" || true; fail 'the ticket decision differs between note it and prove it real'; }
  # the queue: the note is a low finding of #3; the real line is no finding the owner rules
  grep -q '^findings:3	.*0 high, 0 medium, 2 low' "$T0/keys-note" || { cp "$T0/keys-note" "$T0/out"; fail 'the note tree does not count two low findings'; }
  grep -q '^findings:3	.*0 high, 0 medium, 1 low' "$T0/keys-real" || { cp "$T0/keys-real" "$T0/out"; fail 'the real line was counted as a finding for the owner to rule'; }
  exit 0 ) || exit 1
# --- part 2: the staging okay, the real: lines and the close -----------------------------------------------------------------
T=$T0/two; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T0/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T0/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T0/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T0/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out .vid/results
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)
ST=$(printf 'staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none\nseed: synthetic')
# dp <okay> <k> <more staging.txt lines>: a passed D1 report, its duties done
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"
  rr_put "$Q" staging.txt "$(printf '%s\n%s' "$ST" "$3")"; rr_put "$Q" duties.txt "$DU"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 step S02 ROW-003 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'closed S02'; sh "$GS" tw-sync > /dev/null 2>&1
L='a real sign-in shows it — ROW-003 breached product — the sign-in fails on a phone'
printf 'ticket 2, pull request 20, head %s\nfinding: real — %s\nfinding: note — a word on the page\n' "$MC" "$L" > ".vid/results/pr-20-$(printf %.12s "$MC").txt"
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
# the okay lists the open real line, numbered, and asks its answer keyed by its own issue; the note is not listed
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T0/out"); B=$T/gh/issues/$O/body
grep -qxF -- "- 1. $L" "$B" || { cp "$B" "$T0/out"; fail "the okay does not list the open finding: real line as 1"; }
grep -qF 'real: #<this issue>-<n> done — <what was run, where>' "$B" && grep -qF 'real: #<this issue>-<n> not done — <why>' "$B" || { cp "$B" "$T0/out"; fail 'the okay does not ask the real: lines by its own issue'; }
! grep -q 'a word on the page' "$B" || fail 'the okay lists a note'
grep -qxF "real${TAB}1${TAB}$L" $K/d1/ask || { cp $K/d1/ask "$T0/out"; fail "the okay's ask does not record its real line"; }
! grep -nE '\.sh\b|[0-9]+\.[0-9]+\.[0-9]+|[Rr]efus|\.vid/' "$B" > "$T0/out" || fail "the okay holds an internal word"
# a passed D1 with no real: line for #O-1 (one for another okay answers nothing): refused, posted back; the close waits on D1
dp "$O" 1 "real: #999-1 done — on another okay"; fetch; sh "$RS" deploy --stage 1 > "$T0/out" 2>&1; ok "^d1${TAB}refused${TAB}1${TAB}staging.txt has no real: line for #$O-1"
cs decide --stage 1; ok '^d1-refused 1 1$'; grep -q "staging.txt has no real: line for #$O-1" "$T/gh/issues/$O/comments/1" || fail "the refusal does not name the real line: $(cat "$T/gh/issues/$O/comments/1")"
cs conds 1; ok '^2 D1 not passed'
# the next, not done: refused again, the second a Q line for the owner; RM may not rule it; the owner's known clears it
dp "$O" 2 "real: #$O-1 not done — no phone to hand on this staging"; fetch
sh "$RS" deploy --stage 1 > "$T0/out" 2>&1; ok "^d1${TAB}refused${TAB}2${TAB}the real check #$O-1 is not done: no phone to hand on this staging\$"
cs decide --stage 1; ok "^d1-item 1 notreal 1 the real check #$O-1 is not done: no phone to hand on this staging"; no '^d1 1 passed'
QR=$(qn "the real check #$O-1 is not done"); [ -n "$QR" ] || fail "no Q line for the real check: $(grep '^- Q' .vid/RUN-STATE.md)"
grep "^- $QR " .vid/RUN-STATE.md | grep -q 'again' && grep "^- $QR " .vid/RUN-STATE.md | grep -q 'known' && grep "^- $QR " .vid/RUN-STATE.md | grep -q 'row' || fail "the Q line lacks again, known or row: $(grep "^- $QR " .vid/RUN-STATE.md)"
! sh "$QS" answer "$QR" --by RM known 'a limit for now' > "$T0/out" 2>&1 || fail 'RM ruled a real check known'
sh "$QS" answer "$QR" known 'phones come with stage 2' > "$T0/out" 2>&1 || fail "the owner's known was refused: $(cat "$T0/out")"
grep -q "^$O-1${TAB}phones come with stage 2${TAB}owner${TAB}20[0-9-]*T" .vid/decide/real-known || fail "the known real check's record: $(cat .vid/decide/real-known 2>/dev/null)"
cs decide --stage 1; ok '^d1 1 passed$'; grep -qxF "real${TAB}1${TAB}not done${TAB}no phone to hand on this staging" $K/d1/read || { cp $K/d1/read "$T0/out"; fail 'the read lacks its real line'; }
cs conds 1; no 'D1 not passed'
# a later candidate's okay lists the line no more: the okay before it passed with it ruled
K2=.vid/decide/stage/1/2; mkdir -p $K2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > $K2/ask; echo "$X" > $K2/commit; : > $K2/named; : > $K2/passed
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O2=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T0/out")
! grep -qF "$L" "$T/gh/issues/$O2/body" || fail 'a later okay listed a real line the okay before it settled'; ! grep -q "^real${TAB}" $K2/d1/ask || fail 'a later okay recorded a settled real line'
# the sort's word and the format, where they stand beside checks/
SR=$CHECKS/../devagent/agents/second-reviewer.md; RF=$CHECKS/../docs/RESULTS-FORMAT.md
[ -f "$SR" ] && [ -f "$RF" ] || { echo 'needs devagent/agents/second-reviewer.md and docs/RESULTS-FORMAT.md for the table and the format'; exit 77; }
grep -c '`prove it real`' "$SR" > /dev/null || fail 'SR names no prove it real'
[ "$(grep -c '^| .* | `prove it real` |$' "$SR")" = 1 ] || fail "SR's table has not one prove it real row: $(grep '^|' "$SR")"
grep '^| .* | `prove it real` |$' "$SR" | grep -q '^| yes | yes | no' || fail "SR's prove it real row is reachable for a line that does not belong or cannot happen: $(grep 'prove it real` |$' "$SR")"
grep -q 'prove it real' "$RF" && grep -q 'finding: real' "$RF" && grep -q '`real: #' "$RF" || fail 'the format does not name prove it real, finding: real and the real: lines'
exit 0
