#!/bin/sh
# Purpose: selftest case — ViD's own publish changes only files ViD put in the folder (FB-3 B1). On the form fixture's toy
# (fixtures/form.sh) with `layout: one`, `spec-path: upstream/vid` and `spec-stamp: STAMP`, the code repository's main holding a
# folder the team keeps: a README, pages, tests, an inventory, an older PRD.md and a stamp. The first publish's branch changes the
# export's files and the stamp alone: nothing is deleted, and every file of the team's stays as it was. That pull request merged, the
# team then edits design/b.md there; the spec drops design/a.md and design/b.md: the next publish deletes design/a.md, the one file
# ViD put there and nobody touched, and nothing else. Each publish reads the
# code repository's main as it stands (no fetch is made for it here). A changed stamp name deletes the old stamp ViD wrote. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-keeps: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; C=$T/code.git
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\nspec-stamp: STAMP\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
mkdir -p design; echo 'one' > design/a.md; echo 'two' > design/b.md; g add design; g commit -qm 'a design'; git rev-parse HEAD > .vid/tw/applied
# the team's folder on main
D=$T/dev/upstream/vid; mkdir -p "$D/html" "$D/tests/spec"
for f in README.md html/a.html tests/spec/rel.md INVENTORY.md PRD.md STAMP; do echo "the team's $f" > "$D/$f"; done
dev() { ( cd "$T/dev" && "$@" ) > /dev/null 2>&1 || fail "the team's clone: $*"; }
tg() { git -C "$T/dev" -c user.name=team -c user.email=team@example.invalid "$@" > /dev/null 2>&1 || fail "the team's clone: $*"; }
tg add -A; tg commit -qm 'the team folder'; tg push -q origin main; M0=$(git --git-dir="$C" rev-parse main)
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "spec-publish exited $RC"
  P=$(sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p' .vid/tw/log | tail -n 1); BC=$(git --git-dir="$C" rev-parse "refs/heads/$(cat "$FAKEGH/prs/$P/head")"); git --git-dir="$C" diff --no-renames --name-status "$(git --git-dir="$C" rev-parse main)" "$BC" > "$T/ch"; }
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'; E=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log)
sp; cp "$T/ch" "$T/out"; ! grep -q '^D' "$T/ch" || fail "the first publish deletes files of the folder: $(grep -c '^D' "$T/ch" | tr -d ' ') D lines"
for f in README.md html/a.html tests/spec/rel.md INVENTORY.md; do [ "$(git --git-dir="$C" rev-parse "$BC:upstream/vid/$f")" = "$(git --git-dir="$C" rev-parse "$M0:upstream/vid/$f")" ] || fail "the team's $f was changed"; done
{ git --git-dir=.vid/spec.git ls-tree -r --name-only "$E" | sed 's|^|upstream/vid/|'; echo upstream/vid/STAMP; } | sort > "$T/want"; cut -f2 "$T/ch" | sort > "$T/got"
[ -z "$(comm -13 "$T/want" "$T/got")" ] || fail 'the publish changes a file that is not the export'"'"'s'
for f in PRD.md design/a.md design/b.md; do [ "$(git --git-dir="$C" rev-parse "$BC:upstream/vid/$f")" = "$(git --git-dir=.vid/spec.git rev-parse "$E:$f")" ] || fail "$f is not the export's"; done
[ "$(git --git-dir="$C" show "$BC:upstream/vid/STAMP")" = "$E" ] || fail 'the stamp does not name the export'
# merged; the team edits design/b.md; the spec drops both
gh pr merge "$P" -R owner/code --merge > /dev/null || fail 'the fake could not merge the publish'
tg pull -q origin main; echo 'the team says more' >> "$D/design/b.md"; tg commit -qam 'our words'; tg push -q origin main
git rm -rq design; g commit -qm 'the design dropped'; git rev-parse HEAD > .vid/tw/applied; sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the second export failed'
sp; cp "$T/ch" "$T/out"; [ "$(grep '^D' "$T/ch")" = "D	upstream/vid/design/a.md" ] || fail "the publish that drops two files does not delete design/a.md alone: $(grep '^D' "$T/ch" | paste -sd ' ' -)"
git --git-dir="$C" cat-file -e "$BC:upstream/vid/README.md" && git --git-dir="$C" show "$BC:upstream/vid/design/b.md" | grep -q 'the team says more' || fail 'a file of the team'"'"'s did not stay'
# a changed stamp name: the old stamp, ViD's, goes; nothing else
gh pr merge "$P" -R owner/code --merge > /dev/null || fail 'the fake could not merge the second publish'
grep -v '^spec-stamp:' .vid/tw/settings > "$T/s"; echo 'spec-stamp: EXPORT' >> "$T/s"; cat "$T/s" > .vid/tw/settings
sp; cp "$T/ch" "$T/out"; [ "$(grep '^D' "$T/ch")" = "D	upstream/vid/STAMP" ] && grep -q '^A	upstream/vid/EXPORT$' "$T/ch" || fail "a changed stamp does not replace the old one alone: $(paste -sd ' ' "$T/ch")"
echo 'spec-publish-keeps: ok'
