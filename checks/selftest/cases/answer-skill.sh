#!/bin/sh
# Purpose: selftest case — the vid-answer skill, every answer of the owner's (GM-4 K6, the skill's half; F9's draft sentence). On
# the writer's toy: in GitHub auto queue.sh makes the compaction question a `Q<n>` line, as before; in GitHub manual it makes none
# (K6: its calls are short). Where skills/ stands beside checks/: vid-answer is a verb (no `user-invocable: false`, no
# "Internal" description), names `/vid:vid-answer <Q<n> or #<n>:<k>> <answer> "<words>"`, runs every answer through
# `queue.sh answer` and names no other recording path, lists the open lines through `queue.sh list`, shows a `door:` line and
# sends it to the vid-fix skill's door, keeps the delegation (`--by delegate`), takes the lock as vid-connect's start does
# outside /vid run's own conversation, holds the answer and decline moves' forms, and says GitHub manual makes no compaction
# question. vid-fix's GitHub manual branch asks a draft through the queue (`queue.sh ask draft`), landed by the owner's yes
# through vid-answer, and no longer asks it outside the queue. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "answer-skill: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh
noev() { grep -v '^context-window ' .vid/metrics-events > "$T/m" || true; cat "$T/m" > .vid/metrics-events; rm -f .claude/settings.json .vid/decide/queue/seen; }
noev; printf 'setup-answered key=github-mode value="auto" words="ViD builds it" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
sh "$QS" sync > "$T/out" 2>&1 || fail 'sync failed in GitHub auto'
grep -q 'compaction point' .vid/RUN-STATE.md || fail 'GitHub auto no longer makes the compaction question'
noev; printf 'setup-answered key=github-mode value="manual" words="by hand, from now on" at=2026-11-19T10:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
sh "$QS" sync > "$T/out" 2>&1 || fail 'sync failed in GitHub manual'
! grep -q '^context-window' "$T/out" || fail 'GitHub manual announced the compaction question'
! grep -q 'compaction point' .vid/RUN-STATE.md || fail 'GitHub manual made the compaction question a Q line'
sh "$QS" list > "$T/out" 2>&1 || fail 'queue.sh list failed in GitHub manual'
! grep -q 'context:window' "$T/out" || fail 'GitHub manual lists the compaction question'
# the skill's text, where skills/ is beside checks/
S=$CHECKS/../skills; [ -d "$S/vid-run" ] || { echo 'answer-skill: ok (no skills/ here)'; exit 0; }
A=$S/vid-answer/SKILL.md; [ -f "$A" ] || fail 'there is no vid-answer skill'
fl() { tr '\n' ' ' < "$1" | tr -s ' '; }
awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$A" > "$T/fm"
grep -q '^name: vid-answer$' "$T/fm" || fail 'vid-answer has no name line'
! grep -q '^user-invocable: false' "$T/fm" && ! grep -qE '^description: *"?Internal' "$T/fm" || fail 'vid-answer is not a verb'
grep -qF '/vid:vid-answer <Q<n> or #<n>:<k>> <answer> "<words>"' "$A" || fail 'vid-answer does not give the owner'"'"'s command'
fl "$A" > "$T/a"
grep -qF 'sh checks/queue.sh answer' "$T/a" && grep -qF 'sh checks/queue.sh list' "$T/a" || fail 'vid-answer does not run queue.sh answer and list'
! grep -qE 'queue/answers|>> *\.vid' "$T/a" || fail 'vid-answer records an answer by another path'
grep -qF '`door:`' "$T/a" && grep -qF "vid-fix skill's ticket-mode branch" "$T/a" || fail 'vid-answer does not send a door: line to the vid-fix door'
grep -qF -- '--by delegate' "$T/a" || fail 'vid-answer lacks the delegation'
grep -qF "vid-connect skill's start" "$T/a" && grep -qF "/vid run's own conversation" "$T/a" || fail 'vid-answer does not take the lock as a direct call does'
grep -qF 'answer "#<n>:<k>" there "<words>"' "$T/a" && grep -qF 'decline <what> ["<subject>"] "<words>"' "$T/a" || fail 'vid-answer does not hold the answer and decline moves'
grep -qF 'GitHub manual makes no compaction question' "$T/a" || fail 'vid-answer does not say GitHub manual makes no compaction question'
# F9: vid-fix's GitHub manual branch asks a draft through the queue, landed through vid-answer
F=$S/vid-fix/SKILL.md; grep '^\*\*Ticket mode (v0.26.10.25.5, R1)' "$F" > "$T/f" || fail 'vid-fix has no ticket-mode branch'
grep -qF 'queue.sh ask draft <n>' "$T/f" && grep -qF 'vid-answer' "$T/f" || fail "vid-fix's ticket-mode branch does not ask the draft through the queue, landed through vid-answer"
! grep -qF 'never through the queue' "$T/f" || fail "vid-fix's GitHub manual branch still asks a draft outside the queue"
! grep -qF '(the vid-run skill, the owner'"'"'s queue)' "$F" || fail 'vid-fix still sends the yes to the run skill'"'"'s queue'
echo 'answer-skill: ok'
