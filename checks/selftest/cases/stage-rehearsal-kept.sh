#!/bin/sh
# Purpose: selftest case — the rehearsal checks that permanent records survive (0.26.11.1.1, R5), checks/close.sh and results.sh on
# the writer's toy and the fake gh. Stage 1 is planted closed at candidate 1 (its C3, D1 and CS passed), production running an earlier
# commit. The rehearsal okay holds the sentence (note every row of each table the product only ever adds to, check each still there,
# word for word, report kept: lines); a passed RH report with no kept: line is not read, nor one whose deploy.xml has no kept step,
# nor one whose kept: line is of no form; `outcome: failed kept` is routed as any failed step, asked again at k+1; a passed one with
# its kept: lines is read, CR follows, and the owner's production question says the records kept, table by table; a rehearsal that
# reports `kept: none — <why>` makes the question say none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-rehearsal-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
# dp <okay> <k> <report.txt> <steps>: a rehearsal report, its change.txt plain
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf '%s\ndecisions: none' "$3")"; rr_put "$Q" change.txt "$(printf 'migrates: yes\ndrops: none\nservices: none')"; P=''; for x in $4; do P="$P $x=pass"; done; rr_put "$Q" deploy.xml "$(rr_cases $P)"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
P0=$(git --git-dir="$T/code.git" rev-parse main); printf '%s\tD2 #0\t2026-11-01T00:00:00Z\n' "$P0" > .vid/decide/production   # production runs the first commit
tk 2 skeleton S01 ROW-003 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p $K/d1 $K/cs; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit
: > $K/named; : > $K/passed; : > $K/d1/passed; : > $K/cs/passed; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
# the rehearsal okay: the sentence
cs okay --rehearsal 1; ok '^asked [0-9]* okay rehearsal-1$'; H=$(sed -n 's/^asked \([0-9]*\) okay rehearsal-1$/\1/p' "$T/out"); B=$T/gh/issues/$H/body
grep -qF 'Before the migration, note every row of each table the product only ever adds to. After it, check each of those rows is still there, word for word, and report `kept:` lines.' "$B" || fail "the rehearsal okay lacks the sentence: $(cat "$B")"
RP=$(printf 'by: DP\ncommit: %s\noutcome: passed\nsealed: yes\ncopy: http://127.0.0.1:5101\nsignin: subscriber http://127.0.0.1:5101/signin' "$X")
# a passed report with no kept: line, one with no kept step, one with a kept: line of no form: none read
dp "$H" 1 "$RP" 'restore migrate kept boot'; fetch; sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok "^rh${TAB}refused${TAB}1${TAB}a passed rehearsal has no kept: line\$"
dp "$H" 1 "$(printf '%s\nkept: audit_log — 12 rows' "$RP")" 'restore migrate boot'; fetch; sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok "^rh${TAB}refused${TAB}1${TAB}deploy.xml has no kept step\$"
dp "$H" 1 "$(printf '%s\nkept: audit_log twelve' "$RP")" 'restore migrate kept boot'; fetch; sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok "^rh${TAB}refused${TAB}1${TAB}a kept: line is not"
cs decide --stage 1; ok '^rh-refused 1 1$'
# a failed kept: a failed step, asked again at k+1
dp "$H" 2 "$(printf 'by: DP\ncommit: %s\noutcome: failed kept\nproduct change: no\nkept: audit_log — 11 rows' "$X")" 'restore migrate kept'; fetch; cs decide --stage 1; ok '^rh-failed 1 kept$'
grep -rqx 'vid: failed at kept: deploy again and report as attempt 3' "$T/gh/issues/$H/comments" || fail 'a failed kept was not asked again at k+1'
# passed with its kept: lines: read, CR, and the production question says the records kept
dp "$H" 3 "$(printf '%s\nkept: audit_log — 12 rows\nkept: payments — 3 rows' "$RP")" 'restore migrate kept boot'; fetch
sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok "^rh${TAB}passed${TAB}3\$"; ok "^kept${TAB}audit_log — 12 rows\$"
cs decide --stage 1; ok '^rh 1 passed$'; cs owed; ok '^cr 1$'; cs ask --cr 1; N=$(sed -n 's/^asked \([0-9]*\) cr stage-1$/\1/p' "$T/out")
if [ -n "$N" ]; then P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cr/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; fi
ok '^production-yes-asked 1 1$'
grep -q 'records kept: audit_log — 12 rows, payments — 3 rows' $K/yes || fail "the production question lacks the records kept: $(cat $K/yes)"
# kept: none: the question says none
cs okay --rehearsal 1; [ "$RC" != 0 ] || fail 'a second rehearsal okay while one counts'
rm -rf $K/rh $K/cr $K/yes; cs okay --rehearsal 1; H=$(sed -n 's/^asked \([0-9]*\) okay rehearsal-1$/\1/p' "$T/out"); [ -n "$H" ] || fail "no second rehearsal okay: $(cat "$T/out")"
dp "$H" 1 "$(printf '%s\nkept: none — the product has no table it only adds to' "$RP")" 'restore migrate kept boot'; fetch; cs decide --stage 1; ok '^rh 1 passed$'
cs ask --cr 1; N=$(sed -n 's/^asked \([0-9]*\) cr stage-1$/\1/p' "$T/out"); if [ -n "$N" ]; then P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cr/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; fi
grep -q 'records kept: none' $K/yes || fail "kept: none is not said as none: $(cat $K/yes)"
exit 0
