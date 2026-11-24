#!/bin/sh
# Purpose: selftest case — with one repository in GitHub manual the export is kept in the project and saved with the records (FB-3 B2).
# On the form fixture's toy (fixtures/form.sh) with `layout: one` and no `spec-repo:`: github.sh access is ready and lists no spec
# repository, spec-setup has nothing to make, the writer's gate asks none, and spec-export logs `export <E1> from=<H> state=local`, E1 at
# refs/vid/export. The same spec exported again from the same saved state is E1 again. E1 published, ticket S01 refused while the form is newer than the export, then posted at E1, the
# spec changed, E2 exported (its parent E1), the records saved: the bundle holds refs/vid/export. The folder removed and restored in an empty
# one: refs/vid/export and .vid/spec.git's main are E2, E1 resolves and is its ancestor, and the ticket at E1 passes its check; the
# next export changes nothing, the publish goes out, and a third export's parent is E2, its publish changing PRD.md and the stamp alone;
# after a git gc .vid/spec.git is whole. Nothing is ever asked of, or pushed to, the old spec repository. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "export-local-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; C=$T/code.git; XR=refs/vid/export
fm_toy "$T/toy" || fail 'the toy could not be made'; SR=$FAKEGH/repos/owner%code-spec/remote.git
grep -v '^layout:\|^spec-repo:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\nspec-stamp: STAMP\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
: > "$FAKEGH/log"; gh_wclear
x() { sh "$GS" "$@" > "$T/out" 2>&1 || fail "github.sh $1 failed"; }
last() { awk '$1 == "export" { l = $0 } END { print l }' .vid/tw/log; }
app() { g commit -qam "$1"; git rev-parse HEAD > .vid/tw/applied; }
x access; grep -qx 'access: ok' "$T/out" && ! grep -q spec-repo "$T/out" || fail 'access is not ready without a spec repository, or lists one'
RC=0; sh "$GS" spec-setup > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'kept in the project' "$T/out" || fail "spec-setup did not say there is nothing to make ($RC)"
sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || :; ! grep -q 'spec-repo' "$T/out" || fail 'the writer'"'"'s gate asks a spec-repo:'
x spec-export; E1=$(last | cut -d' ' -f2); last | grep -qE "^export $E1 from=$(cat .vid/tw/applied) state=local at=" || fail "the export's line is not a local one: $(last)"
[ "$(git rev-parse -q --verify $XR || true)" = "$E1" ] || fail 'refs/vid/export is not the export'
# the same spec from the same saved state: the same commit
cp -R "$T/toy" "$T/two"; ( cd "$T/two"; git update-ref -d $XR; rm -rf .vid/spec.git; grep -v '^export ' .vid/tw/log > "$T/lg" || :; cat "$T/lg" > .vid/tw/log; sleep 1; sh "$GS" spec-export ) > "$T/out" 2>&1 || fail 'the export in the copy failed'
[ "$(git -C "$T/two" rev-parse $XR)" = "$E1" ] || fail 'the same spec exported again is another commit'
x spec-publish --words 'Yes, publish the spec'; fm_prep S01 || { cp "$T/post" "$T/out"; fail 'S01 could not be written'; }
# the form changed with no export since: the ticket is refused by ViD's newest export, never by a spec repository; then put back
cp forms/issue.md "$T/form"; echo 'One more line.' >> forms/issue.md; g commit -qam 'the form changed'; RC=0; sh "$GS" tw-post --words 'Yes, publish S01' "$FM_F" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "the applied version ViD's newest export holds" "$T/out" || fail "a ticket older than the form was not refused by ViD's newest export ($RC)"
cp "$T/form" forms/issue.md; g commit -qam 'the form put back'; x tw-post --words 'Yes, publish S01' "$FM_F"; N=$(awk '$1 == "published" { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N" ] || fail 'S01 was not posted'
grep -q "^- export: $E1\$" ".vid/tw/out/issue-$N.md" || fail 'the ticket does not rest on E1'
echo 'A new line for the spec.' >> PRD.md; app 'the spec changed'; x spec-export; E2=$(last | cut -d' ' -f2); [ "$(git rev-parse "$E2^")" = "$E1" ] || fail "E2's parent is not E1"
x state-save
# lost and restored
cd "$T"; rm -rf "$T/toy"; mkdir "$T/new"; cd "$T/new"; sh "$GS" state-restore owner/vid-state > "$T/out" 2>&1 || fail 'the restore failed'
[ "$(git rev-parse -q --verify $XR || true)" = "$E2" ] && [ "$(git --git-dir=.vid/spec.git rev-parse refs/heads/main)" = "$E2" ] || fail 'after the restore the newest export is not E2'
git --git-dir=.vid/spec.git merge-base --is-ancestor "$E1" "$E2" && git --git-dir=.vid/spec.git cat-file -e "$E1:PRD.md" || fail 'after the restore E1 does not resolve, or is not on the line'
sh "$CHECKS/writer.sh" check ".vid/tw/out/issue-$N.md" > "$T/out" 2>&1 || fail 'after the restore the ticket at E1 fails its check'
x spec-export; grep -q 'changes nothing' "$T/out" && [ "$(git rev-parse $XR)" = "$E2" ] || fail 'after the restore the same spec is another export'
x spec-publish; P=$(sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p' .vid/tw/log | tail -n 1); gh pr merge "$P" -R owner/code --merge > /dev/null || fail 'the fake could not merge'; x results-fetch
echo 'A third line for the spec.' >> PRD.md; app 'the spec again'; x spec-export; E3=$(last | cut -d' ' -f2); [ "$(git rev-parse "$E3^")" = "$E2" ] || fail "E3's parent is not E2"
x spec-publish; P=$(sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p' .vid/tw/log | tail -n 1)
[ "$(git --git-dir="$C" diff --name-only main "refs/heads/$(cat "$FAKEGH/prs/$P/head")" | paste -sd ' ' -)" = 'upstream/vid/PRD.md upstream/vid/STAMP' ] || fail "E3's publish changes more than PRD.md and the stamp"
git gc -q --prune=now; [ -z "$(git --git-dir=.vid/spec.git rev-list --objects "$E3" 2>&1 >/dev/null)" ] || fail 'after a git gc .vid/spec.git is not whole'
[ -z "$(git --git-dir="$SR" for-each-ref)" ] && ! grep -q 'code-spec' "$FAKEGH/log" && ! grep -q 'code-spec' "$FAKEGH/writes" || { grep code-spec "$FAKEGH/log" > "$T/out" || :; fail 'the spec repository was read, made or pushed to'; }
echo 'export-local-one: ok'
