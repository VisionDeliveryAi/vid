#!/bin/sh
# Purpose: selftest case — ViD's own work reads the applied spec in GitHub manual (GM-4 E12, GM M3), checks/close.sh, grade.sh,
# results.sh, walk.sh and end.sh on the writer's toy and the fake gh, stage 1 due. Pending (after .vid/tw/applied): a requirement
# added to stage 1 (REQ-099, of FEAT-01) with its row (ROW-099, citing a screen), a screen cited by ROW-001 (none applied), the
# hosting block's staging line changed, a later requirement (REQ-098, of a new FEAT-04 in a new stage 3) and a PRD question (OQ-9).
# Stage 1's grade ask names no such requirement, the owner's grade ask neither asks nor defers it; the results reader's inventory ids
# leave the pending row out, so the rest chunk's case named for it is unmatched; the staging okay quotes the applied hosting block,
# never the pending line; the walk brief quotes neither the pending row nor ROW-001 by its pending screen; the completion report lists
# no pending requirement, row or question, and reads the final stage as the applied stages have it (stage 2, in production). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "manual-own-work-applied: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
# stage 1's tickets accepted, each row accepted
tk() { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: %s\n\n## Rows\n\n' "$1" "$2" "$3" "$5" > ".vid/tw/out/issue-$1.md"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done >> ".vid/tw/out/issue-$1.md"
  gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null; printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log
  ( cd "$T/dev" && g commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); P=step-$1-$(printf %.12s "$MC")
  echo "$P" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$P" "$1" "$MC" "$MC" >> .vid/decide/merges; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003,ROW-004 0; tk 3 step S02 ROW-001 1; tk 4 step S03 ROW-006,SEAM-001,RULE-001 1; tk 5 step S04 ROW-002 1
for r in ROW-003 ROW-004 ROW-001 ROW-006 ROW-002 RULE-001 SEAM-001; do tw_hand "row $r accepted"; done; tw_hand 'closed S01'
# pending: REQ-099 in stage 1, the staging line of the hosting block
awk '{ print } /^REQ-001 \| / { print "REQ-099 | functional | T1 | A digest names its sender. | fail-if: a digest names no sender | serves: trust | authority: authoritative | source: seed | covers: DIM-notifications | phase: pilot | feature: FEAT-01" }' PRD.md > P.x && mv P.x PRD.md
sed 's/^staging: .*/staging: a pending address no team has/' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
# pending too: ROW-099 (REQ-099, a screen), a screen for ROW-001 (stage 1, none applied), REQ-098 later in FEAT-04, stage 3 holding FEAT-04, the question OQ-9
awk '{ print } /^ROW-020 \| / { print "ROW-099 | behavior | REQ-099 | anonymous | S01/sender | A digest names its sender. Fails if a digest names no sender. | REQ-099 | owed: spec-only — first stage | origin: REQ-099" }' INVENTORY.md > I.x && mv I.x INVENTORY.md
sed 's/^\(ROW-001 | behavior | REQ-001 | anonymous | \)n\/a |/\1S01\/pending |/' INVENTORY.md > I.x && mv I.x INVENTORY.md; grep -q '^ROW-001 | behavior | REQ-001 | anonymous | S01/pending |' INVENTORY.md || fail 'the toy did not give ROW-001 a pending screen'
awk '{ print } /^FEAT-03 \| / { print "FEAT-04 | G1 | the digest'"'"'s later polish" } /^REQ-099 \| / { print "REQ-098 | functional | T2 | A digest can be read aloud. | fail-if: a digest cannot be read aloud | serves: reach | authority: authoritative | source: seed | covers: DIM-notifications | phase: later | feature: FEAT-04" } END { print ""; print "VID-QUESTION: (OQ-9) Should a digest name its sender by name or by address?" }' PRD.md > P.x && mv P.x PRD.md
awk '{ print } /^STAGE-2 \| / { print "STAGE-3 | The later polish | features: FEAT-04" }' STAGES.md > S.x && mv S.x STAGES.md
g add PRD.md ARCHITECTURE.md INVENTORY.md STAGES.md; g commit -qm 'a requirement, its row, a later one, a stage, a question and a hosting line, not applied'
sh "$CHECKS/stages.sh" scope --upto 1 --reqs 2>/dev/null | grep -qx 'REQ-099' || fail 'the toy did not put the pending requirement in stage 1'
sh "$CHECKS/stages.sh" scope --upto 1 2>/dev/null | grep -qx 'ROW-099' || fail 'the toy did not put the pending row in stage 1'
# stage 1's grade ask
cs ask --stage 1; [ "$RC" = 0 ] || fail "the stage's ask exited $RC"; K=.vid/decide/stage/1/1; G=$(sed -n 's/^issue\t//p' "$K/s1ask"); [ -n "$G" ] || fail 'no grade ask for stage 1'
RQ=$(sed -n 's/^requirements: //p' "$K/s1body"); case " $RQ " in *' REQ-001 '*) ;; *) fail "the stage's grade ask names no applied requirement: $RQ" ;; esac
case " $RQ " in *' REQ-099 '*) fail "the stage's grade ask names the pending requirement: $RQ" ;; esac
# the rest chunk: a case named for the pending row is unmatched, the applied inventory holding no ROW-099 (results.sh invids)
grep -q "^chunk${TAB}p1cx${TAB}" "$K/ask" || fail "stage 1's close ask has no rest chunk: $(cat "$K/ask")"
N=$(awk -F"$TAB" '$1 == "issue" { print $2; exit }' "$K/ask"); X=$(awk -F"$TAB" '$1 == "commit" { print $2; exit }' "$K/ask"); Q=req-$N-p1cx-1; mkdir -p "$T/r"
rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-099_names_its_sender=pass ROW-001_one_digest=pass)"
rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$Q" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$Q"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$Q"
sh "$GS" results-fetch > /dev/null 2>&1 || fail 'the results fetch failed'
RC=0; sh "$CHECKS/results.sh" close --stage 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the results reader exited $RC"
grep -qx "chunk${TAB}p1cx${TAB}green${TAB}1" "$T/out" || fail 'the rest chunk was not read green'
grep -qx "unmatched${TAB}ROW-099_names_its_sender${TAB}passed" "$T/out" || fail 'the results reader matched a case to the pending row ROW-099: its inventory ids are not the applied ones'
! grep -q "^unmatched${TAB}ROW-001_" "$T/out" || fail 'the results reader left an applied row out of its inventory ids'
# the owner's grade ask: the pending requirement neither asked nor deferred
RC=0; sh "$CHECKS/grade.sh" ask > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the owner's grade ask exited $RC"; GA=$(sed -n 's/^asked \([0-9]*\) grade ask-.*/\1/p' "$T/out")
! grep -q 'REQ-099' ".vid/decide/grade/$GA/body" || fail "the owner's grade ask names the pending requirement: $(grep 'REQ-099' ".vid/decide/grade/$GA/body")"   # FB-3 A1.6: no issue, its body in ViD's records
# the staging okay: its C3 passed, the applied hosting block quoted
: > "$K/passed"; : > "$K/done"; cs okay --stage 1; [ "$RC" = 0 ] || fail "the staging okay exited $RC"; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); [ -n "$O" ] || fail 'no staging okay'
grep -qx "> staging: the platform's own address" "$T/gh/issues/$O/body" || fail "the okay does not quote the applied hosting block: $(sed -n '/^The hosting:/,/^$/p' "$T/gh/issues/$O/body")"
! grep -q 'a pending address' "$T/gh/issues/$O/body" || fail 'the okay quotes the pending hosting line'
# the walk: CS passed, D1 read; the brief quotes no pending row (walk.sh reads INVENTORY.md and the stage scope at the applied commit)
mkdir -p "$K/cs" "$K/d1" "$T/wk"; printf 'issue\t50\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > "$K/cs/ask"; : > "$K/cs/passed"; printf 'staging\thttp://127.0.0.1:5001\n' > "$K/d1/read"
RC=0; VID_WALK_TMP=$T/wk sh "$CHECKS/walk.sh" brief --stage 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the walk brief exited $RC"
BR=$(tail -n 1 "$T/out")/brief.md; grep -q '^# The walk' "$BR" || fail 'no walk brief'
! grep -q 'ROW-099' "$BR" || { cp "$BR" "$T/out"; fail 'the walk brief quotes the pending row ROW-099'; }
! grep -q 'ROW-001' "$BR" || { cp "$BR" "$T/out"; fail 'the walk brief quotes ROW-001, by the screen its pending line cites'; }
# the completion report: no pending requirement, row or question; the final stage the applied stages' (2, in production), not the pending 3
tw_hand 'production 2 | stand-in: D2 #9 at 0123456789ab'
RC=0; sh "$CHECKS/end.sh" complete > "$T/out" 2>&1 || RC=$?; CR=.vid/decide/completion.md; [ -s "$CR" ] || fail "end.sh complete wrote no report (exit $RC)"
for w in REQ-099 REQ-098 ROW-099 OQ-9; do ! grep -q "$w" "$CR" || { grep "$w" "$CR" > "$T/out"; fail "the completion report lists the pending $w (above)"; }; done
grep -q '(OQ-1)' "$CR" || { cp "$CR" "$T/out"; fail 'the completion report lists no applied PRD question'; }
grep -q '^Stage 2 is in production' "$CR" || { cp "$CR" "$T/out"; fail 'the completion report does not read stage 2 as the final stage, in production: it reads the pending stages'; }
exit 0
