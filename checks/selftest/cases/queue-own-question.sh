#!/bin/sh
# Purpose: selftest case — ViD's own question has a form in the queue (FB-1 B2). In GitHub auto and in GitHub manual, on a ticket-mode
# toy and the fake gh: `queue.sh ask own "<question>" --gates "<rows>"` is taken and prints `asked Q<n> own <id>`; its `Q<n>` is a
# line of `list` (key `own:<id>`, shown "ViD's question: <words>") and of RUN-STATE's open questions with what it gates, and it is
# among the stage close's blockers (`queue.sh blockers`) while open; an answer with no words is refused; `answer Q<n> "<w>"` is
# taken and prints the one `door: /vid fix — the owner answered ViD's question own:<id>: <w> · draft with that answer` line; the
# answered question leaves the list and the blockers; the same question asked twice keeps one id, and a second answer is refused,
# one answer recorded; a second one gating a journey's transition, `ROW-004-T1`, blocks the stage whose
# rows hold the journey ROW-004; nothing is posted to GitHub. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "queue-own-question: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); QS=$CHECKS/queue.sh
gh_fake
for M in auto manual; do P=$T/p-$M; mkdir -p "$P"; cd "$P"; git init -q; : > "$FAKEGH/writes"
  mkdir -p .vid/plan .vid/tw .vid/round; printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n\n## Open product questions\n\n## Notes\n' > .vid/RUN-STATE.md
  printf 'setup-answered key=github-mode value="%s" words="the toy, %s" at=2026-11-19T09:00:00Z\n' "$M" "$M" > .vid/plan/setup
  [ "$M" = auto ] || printf 'owner-questions: all\n' > .vid/tw/settings
  Qw='Which currency does the weekly digest show, the reader'"'"'s or the shop'"'"'s?'
  RC=0; sh "$QS" ask own "$Qw" --gates 'ROW-002' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "$M: ask own was refused (exit $RC)"
  N=$(sed -n 's/^asked \(Q[0-9][0-9]*\) own \([0-9A-Za-z-]*\)$/\1/p' "$T/out"); I=$(sed -n 's/^asked Q[0-9][0-9]* own \([0-9A-Za-z-]*\)$/\1/p' "$T/out")
  [ -n "$N" ] && [ -n "$I" ] || fail "$M: the ask printed no asked Q<n> own <id> line"
  sh "$QS" ask own "$Qw" --gates 'ROW-002' > "$T/out" 2>&1 || fail "$M: the same question asked again was refused"
  grep -qx "asked $N own $I" "$T/out" || fail "$M: the same question asked again did not keep $N, own $I"
  [ "$(grep -c . .vid/decide/queue/own)" = 1 ] || { cp .vid/decide/queue/own "$T/out"; fail "$M: the same question asked twice is recorded twice"; }
  sh "$QS" list > "$T/ql" 2> "$T/out" || fail "$M: queue.sh list failed"
  grep -q "^$N${TB}own:$I${TB}.*${TB}ViD's question: Which currency" "$T/ql" || { cp "$T/ql" "$T/out"; fail "$M: $N is no line of the list"; }
  awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' .vid/RUN-STATE.md | grep -q "^- $N · asked .* · gates ROW-002 · ViD's question: Which currency" || { cp .vid/RUN-STATE.md "$T/out"; fail "$M: $N is no open question in RUN-STATE"; }
  printf 'ROW-002\n' > "$T/rows"; : > "$T/tix"
  sh "$QS" blockers --stage 1 --tickets "$T/tix" --rows "$T/rows" --steps 'S01' > "$T/bk" 2> "$T/out" || fail "$M: queue.sh blockers failed"
  grep -q "own:$I\$" "$T/bk" || { cp "$T/bk" "$T/out"; fail "$M: the open question is not among the stage close's blockers"; }
  RC=0; sh "$QS" answer "$N" '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail "$M: an answer with no words was taken"
  RC=0; sh "$QS" answer "$N" 'The reader'"'"'s currency, always' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "$M: the answer was refused (exit $RC)"
  grep -qxF "door: /vid fix — the owner answered ViD's question own:$I: The reader's currency, always · draft with that answer" "$T/out" || fail "$M: the answer printed no door: line"
  RC=0; sh "$QS" answer "$N" 'The shop'"'"'s currency' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail "$M: a second answer to $N was taken"
  [ "$(grep -c "${TB}own:$I${TB}" .vid/decide/queue/answers)" = 1 ] || { cp .vid/decide/queue/answers "$T/out"; fail "$M: own:$I holds other than one answer"; }
  sh "$QS" list > "$T/ql" 2> "$T/out" || fail "$M: queue.sh list failed after the answer"
  ! grep -q "${TB}own:$I${TB}" "$T/ql" || { cp "$T/ql" "$T/out"; fail "$M: the answered question is still on the list"; }
  sh "$QS" blockers --stage 1 --tickets "$T/tix" --rows "$T/rows" --steps 'S01' > "$T/bk" 2> "$T/out" || fail "$M: queue.sh blockers failed after the answer"
  ! grep -q "own:$I\$" "$T/bk" || fail "$M: the answered question still blocks the stage close"
  # a transition's gate blocks the stage that plans its journey
  sh "$QS" ask own 'Does the digest list the saved searches in the order they were saved?' --gates 'ROW-004-T1' > "$T/out" 2>&1 || fail "$M: the second ask own was refused"
  I2=$(sed -n 's/^asked Q[0-9][0-9]* own \([0-9A-Za-z-]*\)$/\1/p' "$T/out"); [ -n "$I2" ] || fail "$M: the second ask printed no asked line"
  printf 'ROW-004\n' > "$T/rows4"; sh "$QS" blockers --stage 1 --tickets "$T/tix" --rows "$T/rows4" --steps 'S01' > "$T/bk" 2> "$T/out" || fail "$M: queue.sh blockers failed for the transition's gate"
  grep -q "own:$I2\$" "$T/bk" || { cp "$T/bk" "$T/out"; fail "$M: a question gating ROW-004-T1 does not block the stage whose rows hold ROW-004"; }
  [ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail "$M: something was posted to GitHub"; }
  cd "$T"; done
exit 0
