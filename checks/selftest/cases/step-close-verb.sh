#!/bin/sh
# Purpose: selftest case — the step's close through its one entry, `close.sh step <step>` (GM-4 K3, /vid:vid-step-close), in each
# GitHub mode, on the writer's toy and the fake gh. In GitHub auto: a step with no ticket, and one whose ticket has no merge on record,
# refused naming what is missing, nothing posted; once merged, the close asked; with its report pushed, the entry fetches and reads
# it itself and the step closes; called again, refused as closed. In GitHub manual (GM M8, M3): the accepted ticket's merge line
# (`step-<n>-<c12>`) makes the close owed and the entry asks it at that commit; a landing the applied commit does not hold withdrew
# the ask: the entry refuses naming the landing, and neither it nor `owed` tells or closes the ask's issue or asks again; once the
# applied commit holds the landing, the withdrawn ask is told and closed and the close asked again; read green, the step closes and
# its open ticket is closed with one comment, `vid: closed — the step's close passed at <commit12>`. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/auto-t; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "step-close-verb: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
nis() { ls "$T/gh/issues" 2>/dev/null | grep -c . || true; }
ncom() { ls "$T/gh/issues/$1/comments" 2>/dev/null | grep -c . || true; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$1-p1c1-$2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$M")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-003=pass)"; send "$Q"; }
# a project: the toy, S01's ticket #1 (its issue on the fake gh, ROW-003 alone), one engine
proj() { tw_toy "$1"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
  M=$(git --git-dir="$T/code.git" rev-parse main); M12=$(printf %.12s "$M"); printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings
  gh issue create -R $R --title 'Skeleton' --body 'the skeleton' > /dev/null
  printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n' > .vid/tw/out/issue-1.md
  printf 'published 1 kind=skeleton step=S01 rows=ROW-003 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed; }

# --- GitHub auto
proj "$T/auto"; n0=$(nis)
cs step S02; [ "$RC" = 1 ] || fail "a step with no ticket exited $RC"; ok '^refused S02: no ticket of S02 is published'
cs step S01; [ "$RC" = 1 ] || fail "a step not merged exited $RC"; ok '^refused S01: #1 has no merge on record'
[ "$(nis)" = "$n0" ] && [ ! -d .vid/decide/close/S01/1 ] || fail 'a refused close posted or wrote an ask'
echo 2 > .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" > .vid/decide/merges
cs step S01; [ "$RC" = 0 ] || fail "the owed close exited $RC"; ok '^asked [0-9]* close S01$'; N=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/out")
grep -qx "commit: $M" "$T/gh/issues/$N/body" || fail 'the ask names another commit'
cs step S01; [ "$RC" = 0 ] || fail "the out close with no report exited $RC"; ! grep -q '^closed S01' "$T/out" || fail 'closed with no report'
rq "$N" 1; cs step S01; [ "$RC" = 0 ] || fail "the read exited $RC"; ok '^closed S01$'; [ "$(cat "$T/gh/issues/$N/state")" = CLOSED ] || fail 'the ask stayed open'
[ "$(ncom 1)" = 0 ] || fail 'GitHub auto commented on the ticket at the close'
cs step S01; [ "$RC" = 1 ] || fail "a closed step exited $RC"; ok '^refused S01: closed already'

# --- GitHub manual, a toy of its own (the toy's code repository is made once a folder)
T=$T0/man-t; mkdir -p "$T/r"; proj "$T/man"; printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
cs step S01; [ "$RC" = 1 ] || fail "manual: a ticket not accepted exited $RC"; ok '^refused S01: #1 has no merge on record'
# accepted at main's commit (E4's line)
printf 'step-1-%s\n' "$M12" > .vid/decide/merged-prs; printf 'step-1-%s\t1\t%s\t%s\n' "$M12" "$M" "$M" > .vid/decide/merges
cs owed; ok '^close S01$'
cs step S01; [ "$RC" = 0 ] || fail "manual: the owed close exited $RC"; ok '^asked [0-9]* close S01$'; N=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/out")
grep -qx "commit: $M" "$T/gh/issues/$N/body" || fail 'manual: the ask is not at the acceptance commit'
# a landing the team has not got withdraws the ask
printf '\nA line landed, not yet applied.\n' >> PRD.md; git add PRD.md; git commit -qm 'a landing'; LD=$(git rev-parse HEAD); L12=$(printf %.12s "$LD")
printf '%s 2026-11-09T12:00:00Z\n' "$L12" > .vid/decide/close/S01/1/withdrawn; c0=$(ncom "$N"); n0=$(nis)
cs step S01; [ "$RC" = 1 ] || fail "manual: a pending landing's withdrawal exited $RC"; ok "^refused S01: .*landing $L12"
cs owed; ! grep -q '^close S01$' "$T/out" || fail 'manual: a close owed again before its landing is applied'
[ "$(ncom "$N")" = "$c0" ] && [ "$(cat "$T/gh/issues/$N/state")" != CLOSED ] && [ "$(nis)" = "$n0" ] || fail 'manual: a pending landing'"'"'s withdrawal reached the team'
# applied: told, closed, asked again
echo "$LD" > .vid/tw/applied
cs owed; ok '^close S01$'; [ "$(cat "$T/gh/issues/$N/state")" = CLOSED ] || fail 'manual: the withdrawn ask was not closed once applied'
last=$(ls "$T/gh/issues/$N/comments" | sort -n | tail -n 1); head -n 1 "$T/gh/issues/$N/comments/$last" | grep -q "^vid: withdrawn. The landing $L12 " || fail 'manual: the withdrawn ask was not told'
cs step S01; [ "$RC" = 0 ] || fail "manual: the close asked again exited $RC"; ok '^asked [0-9]* close S01$'; N2=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/out")
[ -f .vid/decide/close/S01/2/ask ] || fail 'manual: the close again is not ask 2'
# read green: closed, and its ticket closed with one comment
rq "$N2" 1; cs step S01; [ "$RC" = 0 ] || fail "manual: the read exited $RC"; ok '^closed S01$'
[ "$(cat "$T/gh/issues/1/state")" = CLOSED ] || fail 'manual: the closed step'"'"'s ticket stayed open'
[ "$(ncom 1)" = 1 ] || fail "manual: the ticket has $(ncom 1) comments, not one"
head -n 1 "$T/gh/issues/1/comments/$(ls "$T/gh/issues/1/comments")" | grep -qx "vid: closed — the step's close passed at $M12" || fail "manual: the ticket's comment: $(cat "$T/gh/issues/1/comments"/*)"
cs owed; cs step S01; [ "$RC" = 1 ] || fail "manual: a closed step exited $RC"; [ "$(ncom 1)" = 1 ] || fail 'manual: the ticket was told twice'
echo 'step-close-verb: ok'
