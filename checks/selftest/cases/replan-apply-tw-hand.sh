#!/bin/sh
# Purpose: selftest case — the apply's posts go through the one ticket path (GM-4 F5, K1, J1): `replan.sh apply` posts each
# amendment and each new step through `github.sh tw-hand amend <n>|publish <step> --words "<the owner's words>"` (an amendment
# with `--cause`), and through nothing else: replan.sh names no next-move.sh. On the form fixture's toy (fixtures/form.sh), S02
# posted as #N and S03 as #N3; ROW-012 reworded (a reset, no test added): the apply with its own proposal, once shown, calls
# `tw-hand amend <N> --words <w> --cause <the apply>`. Then ROW-007 (#N3's) reworded and #N3 closed: the apply calls `tw-hand
# publish S03 --words <w>` for its follow-up. A tw-hand that refuses leaves each post owed (`owed amend #<N>`, exit 3), the
# apply's records standing. tw-hand is recorded, not run, by a stand-in github.sh in a scratch copy of checks/ (its other
# subcommands the real ones), so the case reads what the apply asks of the one path. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-apply-tw-hand: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
# replan.sh holds no other path: no next-move.sh call, the posts tw-hand's
grep -n 'next-move\.sh' "$CHECKS/replan.sh" | grep -v '^[0-9]*:[[:space:]]*#' > "$T/out" || :
[ ! -s "$T/out" ] || fail 'replan.sh still calls next-move.sh (above)'
grep -q 'github\.sh" tw-hand' "$CHECKS/replan.sh" || fail 'replan.sh does not post through github.sh tw-hand'
# the scratch copy: github.sh's tw-hand recorded (each argument, | after each), every other call the real github.sh
cp -R "$CHECKS" "$T/ck"; mv "$T/ck/github.sh" "$T/ck/github-real.sh"
cat > "$T/ck/github.sh" <<'SH'
#!/bin/sh
# the self-test's stand-in: tw-hand and spec-publish recorded in $SHIM_LOG, exit $SHIM_RC; every other call the real github.sh
case ${1:-} in tw-hand|spec-publish) for a; do printf '%s|' "$a"; done >> "$SHIM_LOG"; echo >> "$SHIM_LOG"; exit "${SHIM_RC:-0}" ;; esac
exec sh "$(dirname "$0")/github-real.sh" "$@"
SH
SHIM_LOG=$T/calls; export SHIM_LOG; : > "$SHIM_LOG"
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'none\n' > "$T/none"
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
# a reset alone: the apply's own proposal, made and shown first, then applied
sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-012 reworded'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
RC=0; sh "$T/ck/replan.sh" apply --review "$T/none" --words 'Yes, apply the reworded row' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 4 ] || fail "the first apply, its proposal not shown, exited $RC"
RC=0; sh "$T/ck/replan.sh" apply --review "$T/none" --words 'Yes, apply the reworded row' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the apply exited $RC"
grep -q "^tw-hand|amend|$N|--words|Yes, apply the reworded row|--cause|the re-plan applied on the owner's yes, the plan [0-9a-f]*|\$" "$SHIM_LOG" || { cp "$SHIM_LOG" "$T/out"; fail "#$N's amendment did not go through tw-hand amend $N with the owner's words and the apply as its cause"; }
[ "$(grep -c . "$SHIM_LOG")" = 1 ] || { cp "$SHIM_LOG" "$T/out"; fail 'the apply asked tw-hand for more than the one amendment'; }
# a follow-up: ROW-007 (#N3's) reworded, #N3 closed
: > "$SHIM_LOG"
sed 's/opens the unsubscribe page with no sign-in/opens the unsubscribe page at once, with no sign-in/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-007 reworded'; HD=$(git rev-parse HEAD); echo CLOSED > "$FAKEGH/issues/$N3/state"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed before the follow-up'; }
sh "$T/ck/replan.sh" own > "$T/out" 2>&1 || fail "the apply's own proposal could not be made"
grep -q "^S03${TB}ROW-007\$" .vid/next/proposal/followup || { cat .vid/next/proposal/followup > "$T/out"; fail 'the own proposal does not hold the follow-up of S03'; }
RC=0; SHIM_RC=1 sh "$T/ck/replan.sh" apply --review "$T/none" --words 'Yes, apply ROW-007' > "$T/out" 2>&1 || RC=$?
grep -q '^tw-hand|publish|S03|--words|Yes, apply ROW-007|$' "$SHIM_LOG" || { cp "$SHIM_LOG" "$T/out"; fail "S03's follow-up did not go through tw-hand publish S03 with the owner's words"; }
[ "$RC" = 3 ] && grep -q 'owed publish S03' "$T/out" || fail "a refused tw-hand did not leave S03's follow-up owed, exit 3 ($RC)"
[ "$(sed -n 1p .vid/tw/applied)" = "$HD" ] || fail "the apply's records did not stand when its post was refused"
echo 'replan-apply-tw-hand: ok'
