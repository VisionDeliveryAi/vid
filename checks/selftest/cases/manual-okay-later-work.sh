#!/bin/sh
# Purpose: selftest case — the later work a release carries in GitHub manual (GM-4 E9; GM M14, D7), checks/close.sh and results.sh on
# the writer's toy and the fake gh. Stage 1's candidate holds a stage-2 ticket's accepted commit (#2's `step-` merge line) and a
# stage-2 unit's merge (a pull request of .vid/decide/unit-merges tied to #3), and a later commit it does not hold: the staging okay's
# duty later-work-off lists both, by ticket, and not the later one; a D1 report without the duty is refused, one with it passes; the
# rehearsal okay names the list and the duty; the production okay carries the duty. A candidate with no later work has no such duty,
# and in GitHub auto the same records list none. A unit naming a later ticket's sub-issue is listed by that ticket (E4's sub lines),
# and a later ticket merged through a pull request in GitHub auto before the switch stays listed after it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/later-t; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "manual-okay-later-work: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
dev() { ( cd "$T/dev" && g commit -q --allow-empty -m "$1" && git push -q origin main ); git --git-dir="$T/code.git" rev-parse main; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
# tk <n> <step> <header stage>: a step ticket published by hand
tk() { printf '# t\n\n## Header\n\n- number: %s\n- kind: step\n- step: %s\n- stage: %s\n\n## Rows\n\n> ROW-017 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-017 marks: none\n' "$1" "$2" "$3" > ".vid/tw/out/issue-$1.md"
  printf 'published %s kind=step step=%s rows=ROW-017 at=2026-11-09T10:00:00Z\n' "$1" "$2" >> .vid/tw/log; }
# a project in mode <mode>: the toy, stage 1's candidate named at <its commit>, its full run passed
proj() { tw_toy "$1"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out "$T/r"; tw_hand 'engines alpha'
  [ "$2" != manual ] || { printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied; }
  gh issue create -R $R --title t1 --body b > /dev/null; gh issue create -R $R --title t2 --body b > /dev/null; gh issue create -R $R --title t3 --body b > /dev/null; }
cand() { F=.vid/decide/stage/1/1; mkdir -p "$F"; printf 'issue\t90\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$1" > "$F/ask"; echo "$1" > "$F/commit"; : > "$F/named"; : > "$F/passed"; : > "$F/done"; sh "$GS" results-fetch > /dev/null 2>&1 || true; }
# later work: #2 (stage 2) accepted at A, #3's unit merged at U; X the candidate after both; L, a later merge of #3's, after X
later() { tk 2 S05 2; tk 3 S05 2; A=$(dev 'the stage 2 step'); printf 'step-2-%.12s\t2\t%s\t%s\n' "$A" "$A" "$A" >> .vid/decide/merges; printf 'step-2-%.12s\n' "$A" >> .vid/decide/merged-prs
  U=$(dev 'a unit of #3'); printf '31\t3\t%s\t%s\n' "$U" "$U" >> .vid/decide/unit-merges; X=$(dev 'the stage 1 candidate'); cand "$X"
  L=$(dev 'a later unit of #3'); printf '32\t3\t%s\t%s\n' "$L" "$L" >> .vid/decide/unit-merges; sh "$GS" results-fetch > /dev/null 2>&1 || true; }

# --- GitHub manual, later work in the candidate
proj "$T/toy" manual; later
cs okay --stage 1; [ "$RC" = 0 ] || fail "the staging okay exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); [ -n "$O" ] || fail 'no staging okay'; B=$T/gh/issues/$O/body
grep -qx -- '- later-work-off: the work listed below is off for the people using the product' "$B" || fail "the staging okay names no later-work-off duty: $(sed -n '/^Duties:/,$p' "$B")"
grep -qx -- "  - #2, a stage 2 ticket, accepted at $(printf %.12s "$A")" "$B" || fail 'the duty does not list the stage 2 ticket accepted at a commit the candidate holds'
grep -qx -- "  - pull request #31, of #3 (stage 2), merged at $(printf %.12s "$U")" "$B" || fail "the duty does not list the stage 2 unit's merge"
! grep -q 'pull request #32' "$B" || fail 'the duty lists a merge the candidate does not hold'
grep -q "^later-work${TAB}- #2, " "$F/d1/ask" || fail "the okay's record keeps no later-work list"
# D1: a passed report without the duty refused; with it, passed
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done); SM=$(sed -n "s/^rows$TAB//p" "$F/d1/ask" | tr ' ' '\n' | grep . | sed 's/$/ real/; s/^/seam: /')
dp() { Q=deploy-$O-$1; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"
  rr_put "$Q" staging.txt "$(printf 'staging: http://127.0.0.1:5001\ndiffers: none\nseed: synthetic\n%s' "$SM")"; rr_put "$Q" duties.txt "$2"; send "$Q"; sh "$GS" results-fetch > /dev/null 2>&1 || true; }
dp 1 "$DU"; RC=0; sh "$CHECKS/results.sh" deploy --stage 1 > "$T/out" 2>&1 || RC=$?; ok "^d1${TAB}refused${TAB}1${TAB}duties.txt has no line for the duty later-work-off$"
dp 2 "$(printf '%s\nlater-work-off: done — each listed change behind a switch, off' "$DU")"; sh "$CHECKS/results.sh" deploy --stage 1 > "$T/out" 2>&1 || true; ok "^d1${TAB}passed${TAB}2$"
# the rehearsal names the list and the duty; the production okay carries the duty
mkdir -p "$F/d1" "$F/cs" "$F/w1" "$F/cr"; : > "$F/d1/passed"; : > "$F/cs/passed"; : > "$F/w1/done"; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
cs okay --rehearsal 1; [ "$RC" = 0 ] || fail "the rehearsal okay exited $RC"; H=$(sed -n 's/^asked \([0-9]*\) okay rehearsal-1$/\1/p' "$T/out"); BH=$T/gh/issues/$H/body
grep -q 'later-work-off' "$BH" && grep -qx -- "- #2, a stage 2 ticket, accepted at $(printf %.12s "$A")" "$BH" || fail "the rehearsal okay does not name the later work and its duty: $(cat "$BH")"
: > "$F/rh/passed"; : > "$F/cr/ask"; : > "$F/cr/passed"; printf 'production:1:1:%s\tRehearsal passed\n' "$H" > "$F/yes"; sh "$CHECKS/queue.sh" sync > /dev/null 2>&1 || true; RC=0; sh "$CHECKS/queue.sh" answer "production:1:1:$H" yes 'Yes, go live' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the production yes exited $RC"
cs okay --production 1; [ "$RC" = 0 ] || fail "the production okay exited $RC"; P=$(sed -n 's/^asked \([0-9]*\) okay production-1$/\1/p' "$T/out")
grep -qx -- '- later-work-off: the work listed below is off for the people using the product' "$T/gh/issues/$P/body" && grep -q "^later-work${TAB}" "$F/d2/ask" || fail 'the production okay carries no later-work-off duty'

# --- GitHub manual, a withdrawn later ticket: its unit's merge into the candidate stays later work, so the duty stays
T=$T0/wd-t; mkdir -p "$T"; proj "$T/toy" manual; tk 3 S05 2; U=$(dev 'a unit of #3'); printf '31\t3\t%s\t%s\n' "$U" "$U" >> .vid/decide/unit-merges
printf 'withdrawn 3 at=2026-11-09T12:00:00Z\n' >> .vid/tw/log; X=$(dev 'the stage 1 candidate'); cand "$X"
cs okay --stage 1; [ "$RC" = 0 ] || fail "the staging okay after a withdrawal exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
grep -qx -- '- later-work-off: the work listed below is off for the people using the product' "$T/gh/issues/$O/body" && grep -qx -- "  - pull request #31, of #3 (stage 2), merged at $(printf %.12s "$U")" "$T/gh/issues/$O/body" ||
  fail "a withdrawn later ticket's unit merged into the candidate is not listed: $(sed -n '/^Duties:/,$p' "$T/gh/issues/$O/body")"

# --- GitHub manual, a unit naming a sub-issue of a later ticket: resolved to its ticket by the read's sub lines, as E4 maps it
T=$T0/sub-t; mkdir -p "$T"; proj "$T/toy" manual; tk 3 S05 2; U=$(dev 'a unit of #30'); printf '31\t30\t%s\t%s\n' "$U" "$U" >> .vid/decide/unit-merges
printf 'sub\t3\t3\t30\tOPEN\t-\ta part of #3\n' > .vid/round/read; X=$(dev 'the stage 1 candidate'); cand "$X"
cs okay --stage 1; [ "$RC" = 0 ] || fail "the staging okay with a sub-issue's unit exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
grep -qx -- "  - pull request #31, of #3 (stage 2), merged at $(printf %.12s "$U")" "$T/gh/issues/$O/body" ||
  fail "a unit naming a later ticket's sub-issue is not listed by its ticket: $(sed -n '/^Duties:/,$p' "$T/gh/issues/$O/body")"

# --- GitHub auto, then GitHub manual: a later ticket merged through pull request #22 before the switch stays later work
T=$T0/switch-t; mkdir -p "$T"; proj "$T/toy" auto; tk 2 S05 2; A=$(dev 'the stage 2 step, merged in GitHub auto'); printf '22\t2\t%s\t%s\n' "$A" "$A" >> .vid/decide/merges; echo 22 >> .vid/decide/merged-prs
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-10T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
X=$(dev 'the stage 1 candidate'); cand "$X"
cs okay --stage 1; [ "$RC" = 0 ] || fail "the staging okay after the switch exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
grep -qx -- "  - pull request #22, of #2 (stage 2), merged at $(printf %.12s "$A")" "$T/gh/issues/$O/body" ||
  fail "a later ticket merged in GitHub auto before the switch is not listed: $(sed -n '/^Duties:/,$p' "$T/gh/issues/$O/body")"

# --- GitHub manual, a candidate with no later work: no such duty
T=$T0/none-t; mkdir -p "$T"; proj "$T/toy" manual; X=$(dev 'the stage 1 candidate'); cand "$X"
cs okay --stage 1; [ "$RC" = 0 ] || fail "the staging okay with no later work exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
! grep -q 'later-work-off' "$T/gh/issues/$O/body" && ! grep -q "^later-work${TAB}" "$F/d1/ask" || fail 'a candidate with no later work names the duty'

# --- GitHub auto, the same records: no later work listed
T=$T0/auto-t; mkdir -p "$T"; proj "$T/toy" auto; later
cs okay --stage 1; [ "$RC" = 0 ] || fail "the auto staging okay exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
! grep -q 'later-work-off' "$T/gh/issues/$O/body" || fail 'GitHub auto names the later-work-off duty'
exit 0
