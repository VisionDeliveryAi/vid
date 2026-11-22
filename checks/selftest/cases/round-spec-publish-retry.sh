#!/bin/sh
# Purpose: selftest case — a failed GitHub call in the round's folder publish is tried again (FB-1 B5). checks/round.sh on the ticket
# writer's toy (fixtures/tw-toy.sh) and the fake gh, GitHub auto, `layout: one` and `spec-path: upstream/vid`. The fake gh failing
# the folder's tree call once: next prints `failed spec-publish <12>: …`, records no refusal, and .vid/tw/spec-owed holds the
# export; the next step prints `retry spec-publish <12>`, not `idle`; the next next publishes it (its `spec-published` line with no
# `words=` field, FB-1 B6) and the marker goes, the step after printing no retry. Then a newer export, the older pull request's
# close failing once: next prints `failed spec-publish`, the step `retry spec-publish`, and the next next closes it, logs
# `spec-replaced` and clears the marker. With nothing left (no ticket open, each step started or refused), the step says
# `nothing-left`; the marker standing, it says `retry spec-publish <12>` in its place. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-spec-publish-retry: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
printf 'layout: one\nspec-path: upstream/vid\n' >> .vid/tw/settings
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q "$1" "$T/out" || fail "a line: $1"; }
x12() { awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log; }
# the fake gh: while $T/fail-trees exists the git data tree call fails once; while $T/fail-<two words> exists, that call fails once
mv "$T/bin/gh" "$T/bin/gh-fake"; cat > "$T/bin/gh" <<WRAP
#!/bin/sh
k="\$1-\${2:-}"; for a; do case \$a in */git/trees) k=trees ;; esac; done
if [ -f "$T/fail-\$k" ]; then rm -f "$T/fail-\$k"; echo "gh: a 502 for the self-test" >&2; exit 1; fi
exec "$T/bin/gh-fake" "\$@"
WRAP
chmod +x "$T/bin/gh"
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# the tree call fails once: a failed call, no refusal, the marker
touch "$T/fail-trees"; rd next; [ "$RC" = 0 ] || fail "next with a failed tree call exited $RC"; X=$(x12)
[ ! -f "$T/fail-trees" ] || fail 'the scene is wrong: the tree call was never made'
ok "^failed spec-publish $X: "; no '^refused spec-publish'; no '^error spec-publish'
! grep -q '^round-refused what=spec-publish' .vid/metrics-events && ! grep -q '^spec-publish ' .vid/decide/refused || fail 'the failed call was recorded as a refusal'
[ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$X" ] || fail '.vid/tw/spec-owed does not hold the export after the failed call'
rd step; [ "$RC" = 0 ] || fail "the step after the failed call exited $RC"; ok "^retry spec-publish $X\$"; no '^idle'
rd next; [ "$RC" = 0 ] || fail "the next next exited $RC"; no '^failed spec-publish'
L=$(grep "^spec-published pr=[0-9]* export=$X " .vid/tw/log | tail -n 1); [ -n "$L" ] || fail 'the next next did not publish the export'
case $L in *' words='*) fail "the round's publish wrote a words= field: $L" ;; esac
[ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed after a call that finished'
rd step; no '^retry spec-publish'
# a newer export, the older pull request's close failing once
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'; P1=$(sed -n "s/^spec-published pr=\([0-9]*\) export=$X .*/\1/p" .vid/tw/log | tail -n 1)
touch "$T/fail-pr-close"; rd next; [ "$RC" = 0 ] || fail "next with a failed close exited $RC"; Y=$(x12); [ "$Y" != "$X" ] || fail 'the scene is wrong: no new export'
[ ! -f "$T/fail-pr-close" ] || fail 'the scene is wrong: no close was tried'
ok "^failed spec-publish $Y: "; grep -q "^spec-published pr=[0-9]* export=$Y " .vid/tw/log || fail 'the newer export was not published before its cleanup failed'
[ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$Y" ] || fail '.vid/tw/spec-owed does not hold the export after the failed close'
rd step; ok "^retry spec-publish $Y\$"; no '^idle'
rd next; [ "$RC" = 0 ] || fail "the next after the failed close exited $RC"; no '^failed spec-publish'
grep -q "^spec-replaced pr=$P1 " .vid/tw/log || fail "the older pull request #$P1 was not closed by the next call"
[ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed after the close finished'
rd step; no '^retry spec-publish'
# nothing left (no ticket open, each step started or refused): the marker standing, retry in place of nothing-left
for x in $(sed -n 's/^published \([0-9]*\) .*/\1/p' .vid/tw/log); do printf 'withdrawn %s decision=self-test at=2026-11-10T00:00:00Z\n' "$x" >> .vid/tw/log; gh issue close "$x" -R owner/code; done
rd next; rd step; ok '^nothing-left$'
X=$(x12); printf '%s\n' "$X" > .vid/tw/spec-owed; rd step; [ "$RC" = 0 ] || fail "the step with the marker and nothing left exited $RC"
ok "^retry spec-publish $X\$"; no '^nothing-left'
echo 'round-spec-publish-retry: ok'
