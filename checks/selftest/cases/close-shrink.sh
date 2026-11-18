#!/bin/sh
# Purpose: selftest case — a fix loop that doesn't shrink goes to the owner (0.26.10.29.2, R7), checks/close.sh with the queue on the
# writer's toy and the fake gh. S02 (ROW-001, ROW-005) builds on S01 (ROW-003, ROW-004, its dependency rows), both merged; S02's close
# is asked, red, its fix ticket merged, and asked again. Four closes, each on its own toy: red on ROW-003, a dependency row, after
# ROW-001: no fix line, one Q line naming both closes' red rows, the close held; the owner's again writes the fix line. Red on ROW-005
# alone after ROW-001 and ROW-005 (ROW-005 then waiting on another close's fix): a strict subset, a fix line. Red on ROW-001 alone after
# both acted: a strict subset, close-twice alone. Red on ROW-005 alone, landed since the first ask: a fix line. One chunk a row, ROW-003's
# chunk lost and reporting red after ROW-005 had its fix line: the set no longer shrinks, so ROW-003 gets none; ruled a known limit,
# ROW-004's lost chunk then reporting red is a new shrink with its own Q line, never hidden behind the answered one. In case 1 the shrink
# question alone goes to the owner for that close, not its red one. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "close-shrink: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cs() { RC=0; sh "$CHECKS/close.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "$W: no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "$W: a line: $1"; }
key() { printf '%s' "$1" | cksum | cut -d' ' -f1; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
fetch() { sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1; sh "$CHECKS/github.sh" round-read > .vid/round/read 2>/dev/null; }
rq() { Q=req-$N-$1; C0=$2; shift 2; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" cases-alpha.xml "$(rr_cases "$@")"; send "$Q"; }
# tk <kind> <step> <rows,> [<fix key>]: a ticket published by hand, its number in TK; mg <ticket>: merged at a new main commit, MC
tk() { TK=$(gh issue create -R owner/code --title t --body b --label ticket | sed 's/.*\///'); { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$TK" "$1"; for r in $(echo "$3" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done; printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$TK.md"
  printf 'published %s kind=%s step=%s rows=%s%s at=2026-11-09T10:00:00Z\n' "$TK" "$1" "$2" "$3" "${4:+ fix=$4}" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$(($1 + 100))" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$(($1 + 100))" "$1" "$MC" "$MC" >> .vid/decide/merges; tw_close "$1"; sh "$CHECKS/github.sh" tw-sync > /dev/null 2>&1; }
# toy: S01's skeleton ticket and S02's ticket merged, every row accepted; ask 1 of S02's close, its issue in N, its commit in M
toy() { T=$(mktemp -d); tw_toy "$T/toy"; mkdir -p "$T/r" .vid/round .vid/decide .vid/tw/out; sh "$CHECKS/github.sh" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
  printf 'close-chunk-minutes: %s\nclose-wait-minutes: 0\n' "${CM:-20}" >> .vid/tw/settings; tw_hand 'engines alpha'
  tk skeleton S01 ROW-003,ROW-004; mg "$TK"; tk step S02 ROW-001,ROW-005; mg "$TK"; for r in ROW-003 ROW-004 ROW-001 ROW-005; do tw_hand "row $r accepted"; done; tw_hand 'closed S01'
  fetch; cs owed; ok '^close S02$'; cs ask S02; [ "$RC" = 0 ] || fail "$W: the first ask failed"; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out"); M=$MC
  for r in ROW-001 ROW-005 ROW-003 ROW-004; do grep -q "^$r " .vid/decide/close/S02/1/rows || fail "$W: the close leaves out $r"; done; }
# again <red rows…>: the first close's fix tickets merged, the close asked again; its read with the given rows red
fixed() { for f in $(cut -f1 .vid/decide/close/S02/1/fixes); do tk fix S02 "$(awk -F'\t' -v f="$f" '$1 == f { print $2 }' .vid/decide/close/S02/1/fixes | tr ' ' ,)" "$f"; mg "$TK"; done
  fetch; cs owed; ok '^close S02$'; cs ask S02; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out"); M=$MC; }
red() { a=''; for r in ROW-001 ROW-005 ROW-003 ROW-004; do case " $* " in *" $r "*) a="$a $r=fail:broke" ;; *) a="$a $r=pass" ;; esac; done; rq p1c1-1 "$M" $a; fetch; cs decide S02; [ "$RC" = 0 ] || fail "$W: decide failed ($RC)"; }
# 1: red on ROW-003, a dependency row, after ROW-001: the owner's, a Q line naming both, no fix line, the close held; again writes it
( W='red on a dependency row after another'; toy; trap 'rm -rf "$T"' EXIT; red ROW-001; ok '^close-fix S02 ROW-001$'; fixed; red ROW-003
  no '^close-fix'; ok '^close-shrink S02 ROW-003$'; [ "$(grep -c '^fix ' .vid/tw/handed)" = 1 ] || fail "$W: a fix line was written: $(grep '^fix ' .vid/tw/handed)"
  sh "$CHECKS/queue.sh" sync > /dev/null 2>&1; grep -q '· gates step S02 · the close of S02 did not shrink after its fix: red now: ROW-003 · red at the close before it: ROW-001 · .*answer again for a fix ticket, or limit' .vid/RUN-STATE.md || fail "$W: no Q line naming both closes' red rows: $(grep '^- Q' .vid/RUN-STATE.md)"
  ! grep -q '· the close of S02, chunk .*failing:' .vid/RUN-STATE.md || fail "$W: the close's red question, saying a fix ticket is written, went to the owner beside the shrink one"
  cs owed; no 'close S02'; QN=$(sed -n 's/^- \(Q[0-9]*\) · .*did not shrink.*/\1/p' .vid/RUN-STATE.md); sh "$CHECKS/queue.sh" answer "$QN" again 'fix it once more' > "$T/out" 2>&1 || fail "$W: the again answer failed: $(cat "$T/out")"
  cs decide S02; ok '^close-fix S02 ROW-003$' ) || exit 1
# 2: red on ROW-005 alone after ROW-001 and ROW-005, ROW-005 then waiting on another close's open fix: a strict subset, a fix line
( W='a strict subset'; toy; trap 'rm -rf "$T"' EXIT; L9='fix ROW-005 | ROW-005: x in alpha | close #97 of S09: none'; K9=$(key "$L9"); tw_hand "$L9"; mkdir -p .vid/decide/close/S09/1
  printf 'issue\t97\ncommit\t%s\nasked\t2026-11-09T09:00:00Z\nchunk\tp1c1\talpha\tROW-005\n' "$M" > .vid/decide/close/S09/1/ask; printf 'ROW-005\tx in alpha\n' > .vid/decide/close/S09/1/acted; printf '%s\tROW-005\n' "$K9" > .vid/decide/close/S09/1/fixes; tk fix S09 ROW-005 "$K9"; T9=$TK
  red ROW-001 ROW-005; ok '^close-fix S02 ROW-001$'; ok '^close-waits S02 ROW-005$'; mg "$T9"; fixed; red ROW-005; no '^close-shrink'; no '^close-twice'; ok '^close-fix S02 ROW-005$' ) || exit 1
# 3: red on ROW-001 alone after ROW-001 and ROW-005: a strict subset, but ROW-001 red twice: close-twice alone
( W='a strict subset with a row twice'; toy; trap 'rm -rf "$T"' EXIT; red ROW-001 ROW-005; ok '^close-fix S02 ROW-001 ROW-005$'; fixed; red ROW-001; no '^close-shrink'; ok '^close-twice S02 ROW-001$'; no '^close-fix' ) || exit 1
# 4: red on ROW-005 alone, landed since the first ask, after ROW-001: left out of both sets, so a fix line
( W='red only on a row landed since'; toy; trap 'rm -rf "$T"' EXIT; red ROW-001; ok '^close-fix S02 ROW-001$'; sleep 1; printf 'ROW-005 0123456789ab %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/decide/landed; sleep 1; fixed; red ROW-005; no '^close-shrink'; ok '^close-fix S02 ROW-005$' ) || exit 1
# 5: one chunk a row (close-chunk-minutes 0); the second close red on ROW-005 alone, landed since the first ask, and ROW-003's chunk
# lost: ROW-005 has its fix line; ROW-003's late report, red, makes the set not shrink: no fix line for it, the owner's
rq1() { Q=req-$N-$1-1; rm -rf "$T/r/$Q"; shift; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$M")"; rr_put "$Q" cases-alpha.xml "$(rr_cases "$@")"; send "$Q"; }
chk() { awk -F'\t' -v r="$1" '$1 == "chunk" { n = split($4, a, " "); for (i = 1; i <= n; i++) if (a[i] == r) print $2 }' ".vid/decide/close/S02/$2/ask"; }
( W='a late chunk after a fix line'; CM=0; toy; trap 'rm -rf "$T"' EXIT; [ "$(grep -c '^chunk' .vid/decide/close/S02/1/ask)" = 4 ] || fail "$W: the toy's close is not one chunk a row"
  for r in ROW-001 ROW-005 ROW-003 ROW-004; do v=pass; [ "$r" != ROW-001 ] || v=fail:broke; rq1 "$(chk "$r" 1)" "$r=$v"; done; fetch; cs decide S02; ok '^close-fix S02 ROW-001$'
  sleep 1; printf 'ROW-005 0123456789ab %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/decide/landed; sleep 1; fixed
  for r in ROW-001 ROW-005; do v=pass; [ "$r" != ROW-005 ] || v=fail:broke; rq1 "$(chk "$r" 2)" "$r=$v"; done; fetch; cs decide S02; cs decide S02; ok '^close-lost S02 '; ok '^close-fix S02 ROW-005$'
  rq1 "$(chk ROW-003 2)" ROW-003=fail:broke; fetch; cs decide S02; ok '^close-shrink S02 ROW-003$'; no '^close-fix'
  ! grep -q '^fix ROW-003 ' .vid/tw/handed || fail "$W: the late red row got a fix line with no owner answer: $(grep '^fix ' .vid/tw/handed)"
  # the owner rules ROW-003 a known limit; then ROW-004's lost chunk reports red too: a new shrink, its own question to the owner
  sh "$CHECKS/queue.sh" sync > /dev/null 2>&1; QN=$(sed -n 's/^- \(Q[0-9]*\) · .*did not shrink.*red now: ROW-003 .*/\1/p' .vid/RUN-STATE.md); [ -n "$QN" ] || fail "$W: no Q line for ROW-003's shrink"
  printf 'ROW-003\taccepted\taccepted\t2\t%s\tx\n' "$(printf %.12s "$M")" >> .vid/decide/state   # a decided row, which decide.sh rules (as close-fix does)
  sh "$CHECKS/queue.sh" answer "$QN" limit 'leave it' > "$T/out" 2>&1 || fail "$W: the limit was refused: $(cat "$T/out")"
  rq1 "$(chk ROW-004 2)" ROW-004=fail:broke; fetch; cs decide S02; ok '^close-shrink S02 ROW-004$'; no '^close-fix'; sh "$CHECKS/queue.sh" sync > /dev/null 2>&1
  grep -q '· the close of S02 did not shrink after its fix: red now: ROW-004 · red at the close before it: ROW-001' .vid/RUN-STATE.md || fail "$W: the second shrink, after an answered one, reached no Q line: $(grep '^- Q' .vid/RUN-STATE.md)" ) || exit 1
exit 0
