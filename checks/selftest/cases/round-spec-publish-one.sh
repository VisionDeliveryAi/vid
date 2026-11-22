#!/bin/sh
# Purpose: selftest case — with one repository the round's folder publish never stops its tickets (GM-4 K13; GM-4 §1, GitHub auto
# behaves as today). checks/round.sh on the ticket writer's toy (fixtures/tw-toy.sh) and the fake gh, GitHub auto, `layout: one`
# and `spec-path: upstream/vid`, the code repository empty (a branch, no main: the normal start). `github.sh spec-publish` exits 0
# with one line, posting nothing, when the code repository has no main yet; next goes on past it to the skeleton (refused under
# main=absent, as round-main has it), with no `error spec-publish`. Main made: next publishes the folder (a `spec-published` line)
# and the skeleton. A publish refused by a rule (FB-2 B1: GitHub answering a tree that is not the export's, after a call that
# succeeded; a failed call is tried again, round-spec-publish-retry) is one `refused spec-publish` line, the round going on past it,
# and is not tried again while nothing changes; a new export is tried at once, and, published, logged. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-spec-publish-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
printf 'layout: one\nspec-path: upstream/vid\n' >> .vid/tw/settings
git init -q --bare "$T/e.git"; git -C "$T/e.git" symbolic-ref HEAD refs/heads/main; echo "$T/e.git" > "$T/gh/remote"
git clone -q "$T/e.git" "$T/d" 2>/dev/null; git -C "$T/d" checkout -q -b other; git -C "$T/d" -c user.name=a -c user.email=a@b commit -q --allow-empty -m x; git -C "$T/d" push -q origin other 2>/dev/null
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# no main: spec-publish one line, exit 0, nothing posted; the round goes on
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'
gh_wclear; RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && [ "$(grep -c . "$T/out")" = 1 ] && grep -q 'no main' "$T/out" || fail "with no main spec-publish did not exit 0 with one line naming it ($RC)"
[ ! -s "$FAKEGH/writes" ] && ! grep -q '^spec-published ' .vid/tw/log || fail 'with no main spec-publish posted or logged'
rd next; [ "$RC" = 0 ] || fail "next on an empty code repository exited $RC"; no '^error spec-publish'; ok '^refused new skeleton'
# main made: the folder published, then the skeleton
git -C "$T/d" checkout -q -b main; git -C "$T/d" -c user.name=a -c user.email=a@b commit -q --allow-empty -m 'the first commit'; git -C "$T/d" push -q origin main 2>/dev/null
rd step; rd next; [ "$RC" = 0 ] || fail "next with main exited $RC"; no '^error'; ok '^published '
grep -q '^spec-published pr=[0-9]* export=[0-9a-f]\{12\} path=upstream/vid ' .vid/tw/log || fail 'with main the round did not publish the folder'
# a refused publish (the folder's tree GitHub answers is not the export's, a rule): one refused line, the tickets still going out;
# not tried again while nothing changes
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nfor a; do case $a in */git/trees) echo 4b825dc642cb6eb9a060e54bf8d69288fbee4904; exit 0 ;; esac; done\nexec "%s" "$@"\n' "$T/bin/gh-fake" > "$T/bin/gh"; chmod +x "$T/bin/gh"
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'
rd next; [ "$RC" = 0 ] || fail "next with a refused publish exited $RC"; no '^error spec-publish'; ok '^refused spec-publish'; no '^failed spec-publish'
grep -q '^round-refused what=spec-publish' .vid/metrics-events || fail 'the refusal is not recorded'
rd next; [ "$RC" = 0 ] || fail "the next next exited $RC"; no '^refused spec-publish'; no '^error'
# a new export: tried at once, the refusal keyed on the export
mv "$T/bin/gh-fake" "$T/bin/gh"; echo 'Another line for the spec.' >> PRD.md; g commit -qam 'the spec changed again'
rd next; [ "$RC" = 0 ] || fail "next with a new export exited $RC"; no '^refused spec-publish'; no '^error'
X12=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log)
grep -q "^spec-published pr=[0-9]* export=$X12 " .vid/tw/log || fail 'a new export was not published while a refusal of an earlier one stood'
echo 'round-spec-publish-one: ok'
