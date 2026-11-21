#!/bin/sh
# Purpose: selftest case — /vid run makes the spec repository before the restore and the lock (v0.26.10.26.7, R12, W-14),
# checks/github.sh spec-setup --make-only on the writer's toy and the fake gh. With no spec repository, it is made private and
# logged, and nothing is exported; run again, it finds it private; the first export is then spec-export's, as round.sh next makes
# it. The run skill names spec-setup --make-only before state-restore and lock-take; the ticket writer's skill no longer has the
# plan's approval publish. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "spec-setup-make: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
RC=0; sh "$GS" spec-setup --make-only > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "spec-setup --make-only failed ($RC)"; ok 'the spec repository owner/code-spec made, private'
grep -q '^spec-repo owner/code-spec created ' .vid/tw/log || fail 'no spec-repo line'; ! grep -q '^export ' .vid/tw/log || fail "--make-only exported: $(grep '^export ' .vid/tw/log)"
[ "$(gh repo view owner/code-spec --json isPrivate --jq .isPrivate)" = true ] || fail 'the spec repository is not private'
[ -z "$(git --git-dir="$(gh repo view owner/code-spec --json url --jq .url)" for-each-ref 2>/dev/null)" ] || fail 'the spec repository holds a branch before the first round'
RC=0; sh "$GS" spec-setup --make-only > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && ok 'exists (private)' || fail "a second --make-only failed ($RC)"
RC=0; sh "$GS" spec-export > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the round's first export failed ($RC)"; grep -q '^export ' .vid/tw/log || fail 'no export line after spec-export'
# the skills, when SKILL.md files are here (the plugin's layout)
# the connect's (vid-connect, since GM-4 F2 and K10 move the run skill's start there)
SK=$CHECKS/../skills; if [ -f "$SK/vid-connect/SKILL.md" ]; then VC=$SK/vid-connect/SKILL.md
  a=$(grep -n 'spec-setup --make-only' "$VC" | head -n 1 | cut -d: -f1); b=$(grep -n 'state-restore' "$VC" | head -n 1 | cut -d: -f1); c=$(grep -n 'lock-take' "$VC" | head -n 1 | cut -d: -f1)
  [ -n "$a" ] && [ "$a" -le "$b" ] && [ "$a" -lt "$c" ] || fail "the connect does not make the spec repository before the restore and the lock ($a, $b, $c)"
  ! grep -q "owner's go after ratification" "$SK/vid-tickets/SKILL.md" || fail "the ticket writer still publishes at the plan's approval"; fi
echo 'spec-setup-make: ok'
