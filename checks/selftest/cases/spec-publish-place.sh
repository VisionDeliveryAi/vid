#!/bin/sh
# Purpose: selftest case — a publish is its export, its folder and its stamp (GM-4 K13: "the stamp does not name the export
# published" never holds). On the form fixture's toy (fixtures/form.sh) with `layout: one`, spec-path: left out (docs/specs) and no
# stamp: `github.sh spec-publish` logs `spec-published pr=<n> export=<12 hex> path=docs/specs stamp=- at=`. The same export, with
# spec-path: upstream/vid: published again, the branch holding upstream/vid/PRD.md, the line path=upstream/vid. The same export,
# with spec-stamp: STAMP added: published again, upstream/vid/STAMP naming the export commit, the line stamp=STAMP; then called
# again, nothing posted. The apply's own check is spec-publish's (replan.sh calls it after its export, and it decides). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-place: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; C=$T/code.git
fm_toy "$T/toy" || fail 'the toy could not be made'
set_() { grep -v '^layout:\|^spec-path:\|^spec-stamp:' .vid/tw/settings > "$T/s"; printf 'layout: one\n%b' "$1" >> "$T/s"; cat "$T/s" > .vid/tw/settings; }
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "spec-publish exited $RC ($1)"; }
set_ ''; sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'
E=$(git --git-dir=.vid/spec.git rev-parse "$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log)^{commit}"); E12=$(printf %.12s "$E"); B=refs/heads/vid-spec/$E12
sp 'the first publish'; grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -qE "^spec-published pr=[0-9]+ export=$E12 path=docs/specs stamp=- at=" || fail "the line does not name the folder and no stamp: $(grep '^spec-published ' .vid/tw/log | tail -n 1)"
git --git-dir="$C" cat-file -e "$B:docs/specs/PRD.md" || fail 'docs/specs does not hold the export'
set_ 'spec-path: upstream/vid\n'; sp 'a changed folder'
grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -q " export=$E12 path=upstream/vid stamp=- " || fail 'the same export was not published again into the changed folder'
git --git-dir="$C" cat-file -e "$B:upstream/vid/PRD.md" || fail 'the changed folder does not hold the export'
set_ 'spec-path: upstream/vid\nspec-stamp: STAMP\n'; sp 'a stamp added'
grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -q " export=$E12 path=upstream/vid stamp=STAMP " || fail 'the same export was not published again with the stamp added'
[ "$(git --git-dir="$C" show "$B:upstream/vid/STAMP" 2>/dev/null)" = "$E" ] || fail 'the stamp added does not name the export commit'
gh_wclear; sp 'the same again'; [ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail 'the same export, folder and stamp were published again'; }
! grep -q 'SPX' "$CHECKS/replan.sh" || fail "the apply keeps a check of its own of what is published, beside spec-publish's"
exit 0
