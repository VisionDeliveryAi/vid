#!/bin/sh
# Purpose: selftest case — a project whose exports were pushed keeps them when they stay in the project (FB-3 B2). On the ticket writer's
# toy (fixtures/tw-toy.sh), in GitHub auto with `layout: one`, two exports pushed to the spec repository by this same script, each
# moving refs/vid/export with it; the ref then removed, as an older ViD left the project. Then GitHub manual. (1) In place: dropping
# the key is refused; the first call takes .vid/spec.git's main as refs/vid/export with no read of the spec repository, and the key is
# dropped. (2) A save restored with no .vid/spec.git and the key set: the line fetched once from the spec repository, never again. (3) The key gone
# already, .vid/spec.git there: as (1); with neither the copy nor the key, refused, naming what to do. In each the old exports resolve and the
# spec repository's main is untouched. (4) Back in GitHub auto, the spec repository holding a commit of someone else's meanwhile: the first export pushes the
# whole line, every export and that commit on it; a spec-repo: that names the state repository is refused. (5) In
# GitHub auto with two repositories a spec repository put back to an older commit, or a new one, gets what it got before: an export on
# its own main, never the line the project kept; a switch to GitHub manual after that joins the two, no export lost, by
# one commit, the same when made again. Before any GitHub manual an equal state-repo: and spec-repo: stop no export; (4b) back in GitHub auto after a manual
# with no apply, a new spec repository gets the whole line, and (4c) the spec repository as ViD left it the kept exports as they are. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "export-local-migrate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; XR=refs/vid/export
tw_toy "$T/toy"; printf 'layout: one\nstate-repo: owner/vid-state\n' >> .vid/tw/settings; gh repo create owner/vid-state --private > /dev/null
mode() { printf 'setup-answered key=github-mode value="%s" words="the toy" at=%s\n' "$1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/plan/setup; }
x() { : > "$FAKEGH/log"; sh "$GS" "$@" > "$T/out" 2>&1 || fail "github.sh $1 failed"; }
newx() { awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log; }
mode auto; x spec-setup; E1=$(newx); SR=$FAKEGH/repos/owner%code-spec/remote.git; rm_() { git --git-dir="$SR" rev-parse refs/heads/main; }
[ "$(git rev-parse -q --verify $XR || true)" = "$E1" ] || fail 'in GitHub auto the pushed export did not move refs/vid/export'
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'; x spec-export; E2=$(newx); [ "$(rm_)" = "$E2" ] && [ "$(git rev-parse $XR)" = "$E2" ] || fail 'the second export is not pushed, or the ref did not follow'
# before any GitHub manual, the state repository answered as the spec repository (the switch asks it first) stops no export
cp .vid/tw/settings "$T/s1"; sed 's#^state-repo: .*#state-repo: owner/code-spec#' "$T/s1" > .vid/tw/settings; x spec-export; grep -q 'changes nothing' "$T/out" || fail 'the export before a switch is not as before'; cat "$T/s1" > .vid/tw/settings
# as an older ViD left it, then GitHub manual
git update-ref -d $XR; git rev-parse HEAD > .vid/tw/applied; mode manual
for k in copy gone bare; do cp -R "$T/toy" "$T/$k"; done
drop() { RC=0; sh "$CHECKS/planner.sh" setup spec-repo 'not yet' --words 'drop it' > "$T/out" 2>&1 || RC=$?; }
same() { [ "$(git rev-parse -q --verify $XR || true)" = "$E2" ] && [ "$(git --git-dir=.vid/spec.git rev-parse refs/heads/main)" = "$E2" ] && git --git-dir=.vid/spec.git cat-file -e "$E1:PRD.md" && git merge-base --is-ancestor "$E1" "$E2" || fail "$1: the line is not the pushed one"; [ "$(rm_)" = "$E2" ] || fail "$1: the spec repository's main moved"; }
quiet() { ! grep -q 'code-spec' "$FAKEGH/log" || { cp "$FAKEGH/log" "$T/out"; fail "$1 read the spec repository"; }; }
# (1) in place
drop; [ "$RC" != 0 ] && grep -q '^spec-repo:' .vid/tw/settings || fail 'the key was dropped before the exports moved into the project'
x spec-fetch; same 'in place'; quiet 'the update in place'
drop; [ "$RC" = 0 ] && ! grep -q '^spec-repo:' .vid/tw/settings || fail "the key could not be dropped once the exports were in the project ($RC)"
x spec-export; same 'in place, exported'; quiet 'the next export'; grep -q 'changes nothing' "$T/out" || fail 'the same spec was exported again'
# (2) an old save, no copy, the key set
cd "$T/copy"; rm -rf .vid/spec.git; x spec-fetch; same 'an old save'; grep -q 'code-spec' "$FAKEGH/log" || fail 'the scene is wrong: the line came from elsewhere'; x spec-fetch; quiet 'the call after the one fetch'
# (3) the key gone already; and neither
cd "$T/gone"; grep -v '^spec-repo:' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings; x spec-fetch; same 'the key gone'
cd "$T/bare"; cat "$T/s" > .vid/tw/settings; rm -rf .vid/spec.git; RC=0; sh "$GS" spec-export > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'setup spec-repo' "$T/out" || fail "with neither the copy nor the key the export was not refused naming spec-repo ($RC)"
# (4) back to auto
cd "$T/toy"; echo 'A third line.' >> PRD.md; g commit -qam 'the spec again'; git rev-parse HEAD > .vid/tw/applied; x spec-export; E3=$(newx); [ "$E3" != "$E2" ] && [ "$(rm_)" = "$E2" ] || fail 'the third export is none, or was pushed'
git clone -q "$SR" "$T/own" 2>/dev/null; ( cd "$T/own" && echo 'by hand' > NOTES.md && git add -A && git -c user.name=o -c user.email=o@example.invalid commit -qm 'a note' && git push -q origin HEAD:main ) > "$T/out" 2>&1 || fail 'the note could not be pushed'; HN=$(rm_)
mode auto; echo 'spec-repo: owner/vid-state' >> .vid/tw/settings; RC=0; sh "$GS" spec-export > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'state-repo' "$T/out" || fail "in GitHub auto an export to the state repository was not refused ($RC)"
grep -v '^spec-repo:' .vid/tw/settings > "$T/s"; echo 'spec-repo: owner/code-spec' >> "$T/s"; cat "$T/s" > .vid/tw/settings
x spec-export; E4=$(newx); [ "$(rm_)" = "$E4" ] && grep -q "^export $E4 from=.* state=pushed " .vid/tw/log || fail 'the first export back in GitHub auto was not pushed'
for c in "$E1" "$E2" "$E3" "$HN"; do git --git-dir="$SR" merge-base --is-ancestor "$c" "$E4" || fail "back in GitHub auto the spec repository's main lacks $c"; done
[ "$(git rev-parse $XR)" = "$E4" ] || fail 'back in GitHub auto the ref did not follow'
git --git-dir="$SR" show "$E4:PRD.md" | grep -q 'A third line' || fail "the pushed export is not HEAD's"
x spec-export; grep -q 'changes nothing' "$T/out" && [ "$(rm_)" = "$E4" ] || fail 'a second export in GitHub auto pushed again'
# (4b) manual with no apply, then GitHub auto with a new spec repository: the whole line goes there
T0=$T; trap 'rm -rf "$T0"' EXIT; T=$T0/back; mkdir "$T"; tw_toy "$T/toy" > /dev/null; printf 'layout: one\nstate-repo: owner/vid-state\n' >> .vid/tw/settings; mode auto; x spec-setup; B1=$(newx); echo 'Two.' >> PRD.md; g commit -qam 'two'; x spec-export; B2=$(newx)
git rev-parse HEAD > .vid/tw/applied; mode manual; x spec-fetch; x spec-export; gh repo create owner/spec-two --private > /dev/null; sed 's#^spec-repo: .*#spec-repo: owner/spec-two#' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings; SR=$FAKEGH/repos/owner%spec-two/remote.git
mode auto; x spec-export; for c in "$B1" "$B2"; do git --git-dir="$SR" merge-base --is-ancestor "$c" refs/heads/main 2> /dev/null || fail "back in GitHub auto the new spec repository lacks the export $c"; done
# (4c) the plain way back, the spec repository as ViD left it: the local line pushed whole, its newest itself with the spec unchanged
T=$T0/plain; mkdir "$T"; tw_toy "$T/toy" > /dev/null; printf 'layout: one\nstate-repo: owner/vid-state\n' >> .vid/tw/settings; mode auto; x spec-setup; D1=$(newx); SR=$FAKEGH/repos/owner%code-spec/remote.git
echo 'Two.' >> PRD.md; g commit -qam 'two'; git rev-parse HEAD > .vid/tw/applied; mode manual; x spec-export; D2=$(newx); echo 'Three.' >> PRD.md; g commit -qam 'three'; git rev-parse HEAD > .vid/tw/applied; x spec-export; D3=$(newx)
mode auto; x spec-export; [ "$(rm_)" = "$D3" ] && grep -q "^export $D3 from=.* state=pushed " .vid/tw/log || fail 'the plain way back did not push the newest kept export as it is'
for c in "$D1" "$D2"; do git --git-dir="$SR" merge-base --is-ancestor "$c" "$D3" || fail "the plain way back left out the export $c"; done
echo 'Four.' >> PRD.md; g commit -qam 'four'; x spec-export; [ "$(git --git-dir="$SR" rev-parse "$(rm_)^")" = "$D3" ] || fail 'the export after the way back does not follow the kept line'
# (5) GitHub auto and two repositories: what is pushed follows the spec repository's main alone
T=$T0/sep; mkdir "$T"; tw_toy "$T/toy" > /dev/null; mode auto; x spec-setup; A1=$(newx); SR=$FAKEGH/repos/owner%code-spec/remote.git
echo 'Two.' >> PRD.md; g commit -qam 'two'; x spec-export; A2=$(newx); git --git-dir="$SR" update-ref refs/heads/main "$A1"
echo 'Three.' >> PRD.md; g commit -qam 'three'; x spec-export; A3=$(newx); [ "$(git --git-dir="$SR" rev-list --parents -1 "$(rm_)")" = "$A3 $A1" ] || fail 'a main put back to an older commit got the dropped export again'
gh repo create owner/spec-two --private > /dev/null; sed 's#^spec-repo: .*#spec-repo: owner/spec-two#' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings; SR=$FAKEGH/repos/owner%spec-two/remote.git
x spec-export; A4=$(newx); [ "$(rm_)" = "$A4" ] && [ "$(git --git-dir="$SR" rev-list --count "$A4")" = 1 ] || fail "a new spec repository got $(git --git-dir="$SR" rev-list --count main) commits, not the spec's one"
# then GitHub manual with one repository: that line and the older one the project kept are one line, each export on it
printf 'layout: one\nstate-repo: owner/vid-state\n' >> .vid/tw/settings; git rev-parse HEAD > .vid/tw/applied; mode manual; cp -R "$T/toy" "$T/twice"; x spec-fetch
sleep 1; ( cd "$T/twice" && sh "$GS" spec-fetch ) > "$T/out" 2>&1 || fail 'the switch in the copy failed'; [ "$(git -C "$T/twice" rev-parse $XR)" = "$(git rev-parse $XR)" ] || fail 'the joining commit made twice from one state is two commits'
for c in "$A1" "$A2" "$A4"; do git merge-base --is-ancestor "$c" $XR || fail "after the switch the line lacks the export $c"; done
[ "$(git rev-parse "$XR^{tree}")" = "$(git --git-dir="$SR" rev-parse "$A4^{tree}")" ] && [ "$(rm_)" = "$A4" ] || fail 'after the switch the newest export is not the pushed one, or the spec repository moved'
echo 'export-local-migrate: ok'
