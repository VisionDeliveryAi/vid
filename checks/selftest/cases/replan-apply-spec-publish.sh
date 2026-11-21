#!/bin/sh
# Purpose: selftest case — the apply publishes the spec into the code repository's folder with one repository (GM-4 K13, J4's
# core half). On the form fixture's toy (fixtures/form.sh) with `layout: one` and `spec-path: upstream/vid`, S02 posted as #N;
# ROW-012 reworded (a reset): the apply, its own proposal shown, exports at the new applied version and then calls `github.sh
# spec-publish <the export commit>` (the newest export line of .vid/tw/log), before any post; its amendment of #N goes out after,
# through tw-hand. Then ROW-013 reworded and the spec-publish refused: the apply exits 3, saying the publish is owed, and holds
# every post (`owed amend #<N>: held …`), asking tw-hand nothing, its records standing; the next call shows the owed publish as a
# critical line of its own (`apply-owed spec-publish`, naming the apply and the export), beside #<N>'s. (With two repositories the apply calls no
# spec-publish: replan-apply-tw-hand.) spec-publish and tw-hand are recorded, not run, by a stand-in github.sh in a scratch copy
# of checks/, every other subcommand the real one. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-apply-spec-publish: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cp -R "$CHECKS" "$T/ck"; mv "$T/ck/github.sh" "$T/ck/github-real.sh"
cat > "$T/ck/github.sh" <<'SH'
#!/bin/sh
# the self-test's stand-in: tw-hand and spec-publish recorded in $SHIM_LOG (spec-publish exits $SHIM_SP_RC); every other call the real github.sh
case ${1:-} in tw-hand|spec-publish) for a; do printf '%s|' "$a"; done >> "$SHIM_LOG"; echo >> "$SHIM_LOG"; [ "$1" = tw-hand ] || exit "${SHIM_SP_RC:-0}"; exit 0 ;; esac
exec sh "$(dirname "$0")/github-real.sh" "$@"
SH
SHIM_LOG=$T/calls; export SHIM_LOG; : > "$SHIM_LOG"
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'layout: one\nspec-path: upstream/vid\nspec-stamp: STAMP\n' >> .vid/tw/settings
printf 'none\n' > "$T/none"
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-012 reworded'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
RC=0; sh "$T/ck/replan.sh" apply --review "$T/none" --words 'Yes, apply the reworded row' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 4 ] || fail "the first apply, its proposal not shown, exited $RC"
RC=0; sh "$T/ck/replan.sh" apply --review "$T/none" --words 'Yes, apply the reworded row' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the apply exited $RC"
X=$(awk '$1 == "export" { x = $2 } END { print x }' .vid/tw/log); [ -n "$X" ] || fail 'the apply made no export'
[ "$(sed -n 1p "$SHIM_LOG")" = "spec-publish|$X|" ] || { cp "$SHIM_LOG" "$T/out"; fail "the apply's first call to GitHub's posts is not spec-publish $X, the export it made"; }
sed -n 2p "$SHIM_LOG" | grep -q "^tw-hand|amend|$N|--words|Yes, apply the reworded row|" || { cp "$SHIM_LOG" "$T/out"; fail "#$N's amendment did not follow the publish through tw-hand"; }
[ "$(grep -c '^spec-publish|' "$SHIM_LOG")" = 1 ] || { cp "$SHIM_LOG" "$T/out"; fail 'the apply published the spec more than once'; }
# the publish refused: every post held, owed
: > "$SHIM_LOG"
sed 's/Reading the same feed twice leaves/Reading one feed twice leaves/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-013 reworded'; HD=$(git rev-parse HEAD)
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed before the refused publish'; }
sh "$T/ck/replan.sh" own > "$T/out" 2>&1 || fail "the apply's own proposal could not be made"
RC=0; SHIM_SP_RC=1 sh "$T/ck/replan.sh" apply --review "$T/none" --words 'Yes, apply ROW-013' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] && grep -q '^owed spec-publish ' "$T/out" || fail "a refused spec-publish did not leave the publish owed, exit 3 ($RC)"
grep -q "^owed amend #$N: held" "$T/out" || fail "#$N's amendment was not held while the spec is not in the folder"
! grep -q '^tw-hand|' "$SHIM_LOG" || { cp "$SHIM_LOG" "$T/out"; fail 'a post went out to tw-hand while the spec publish was refused'; }
[ "$(sed -n 1p .vid/tw/applied)" = "$HD" ] || fail "the apply's records did not stand when the publish was refused"
# the next call: the owed publish its own critical line
TB=$(printf '\t'); am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read failed at the next call'; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^trigger${TB}critical${TB}apply-owed${TB}spec-publish${TB}the apply $(printf %.12s "$HD") left the spec's publish into the code repository's folder owed" "$T/tr" ||
  { grep '^trigger' "$T/tr" > "$T/out"; fail "the next call does not show the apply's owed spec publish as a critical line of its own"; }
echo 'replan-apply-spec-publish: ok'
