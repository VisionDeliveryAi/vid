#!/bin/sh
# Purpose: selftest case — `next.sh triggers` in GitHub auto (GM-4 K9: /vid run invokes vid-triggers after a step that printed
# something new, in both modes), on the writer's toy and the fake gh. The skeleton's ticket published and open, the run active and a
# `round.sh step` taken: `next.sh triggers` exits 0 and prints none of GitHub manual's lines (no `pending` or `spec` line, no
# implement-replan or planning-analysis move, no team change, no `context ask`). With a plan change that raises a trigger (a step's
# lane no team of the setup gives) it prints that trigger, `trigger critical lane-gone <step>`, and still none of those lines: the
# run's re-plan is the run manager's own (vid-replan's GitHub auto paragraph), never /vid next's analysis. Writes nothing. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "run-triggers-auto: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
sh "$GS" spec-setup > "$T/out" 2>&1 && sh "$GS" tw-sync >> "$T/out" 2>&1 && tw_start S01 && tw_post skeleton || fail "the skeleton's ticket could not be published"
sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
sed 's/^run:.*/run: active/' .vid/RUN-STATE.md > "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md
sh "$CHECKS/round.sh" step > "$T/out" 2>&1 || fail 'the step failed'
# GitHub manual's lines: none in GitHub auto
manual_lines() { grep -E '^(pending|spec|added|dropped)	|^move	(implement-replan|planning-analysis|team-change)	|^trigger	[a-z]*	team-|^quiet	[a-z]*	team-|^context	ask	' "$1" || true; }
tr_() { rm -f "$T/out"; S0=$(find . -path ./.git -prune -o -type f -print | sort | xargs cksum | cksum); RC=0; sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || RC=$?
  [ "$RC" = 0 ] || fail "next.sh triggers in GitHub auto exited $RC"; [ "$(find . -path ./.git -prune -o -type f -print | sort | xargs cksum | cksum)" = "$S0" ] || fail 'next.sh triggers wrote a file'; }
tr_; grep -q '^count	total	' "$T/out" || fail 'no count line in GitHub auto'
[ -z "$(manual_lines "$T/out")" ] || fail "GitHub auto printed GitHub manual's lines: $(manual_lines "$T/out" | head -n 1)"
! grep -q '^trigger	' "$T/out" || fail "a trigger with no plan change: $(grep '^trigger	' "$T/out" | head -n 1)"
# a plan change that raises a trigger: S05's lane one no team of the setup gives
sed 's/^\(step S05 .*| lane: \)devagent/\1another-team/' .vid/RUN-STATE.md > "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md; grep -q '^step S05 .*lane: another-team' .vid/RUN-STATE.md || fail 'the plan change was not made'
tr_; grep -q '^trigger	critical	lane-gone	S05	' "$T/out" || fail 'the plan change raised no lane-gone trigger in GitHub auto'
[ -z "$(manual_lines "$T/out")" ] || fail "GitHub auto printed GitHub manual's lines with a trigger: $(manual_lines "$T/out" | head -n 1)"
exit 0
