#!/bin/sh
# Purpose: selftest case — ViD's records and project on GitHub (v0.26.10.25.1 R6), on the toy. After state-save and a wipe, state-restore <repo> in an empty
# folder gives every saved file byte for byte, the project's history, spec.git and code rebuilt, and the commit checks left off (FB-1 A1: the connect
# switches them on once they pass, never the restore). Nothing changed, nothing pushed. A folder behind the branch catches up, its core.hooksPath as it was;
# a current one is left. A ref added under refs/vid/ while HEAD stays is saved again and restored (GM-3 S2). A repository that is not private is refused by save and restore, naming it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "state-roundtrip: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; SR=$T/gh/repos/owner%code-spec/remote.git; sh "$GS" state-restore > "$T/out" 2>&1 || fail 'a first session was refused'
mkdir -p .vid/decide/rows .vid/results; printf 'a\tb\n' > .vid/decide/counts; printf 'one\n' > .vid/decide/rows/ROW-001.txt; printf 'evidence\n' > .vid/results/pr-1-a.txt; printf '<p>\n' > .vid/results/pr-1-a.html; printf 'x=1\n' > .vid/budget
sh "$GS" state-save > "$T/out" 2>&1 || fail 'state-save failed'; C=$(git -C "$SR" rev-parse refs/heads/vid-state/records); [ "$(git -C "$SR" log -1 --format=%ae "$C")" = vid@export.invalid ] || fail 'the records are not authored as ViD'
sh "$GS" state-save > "$T/out" 2>&1 || fail 'a second save failed'; grep -q 'as saved' "$T/out" && [ "$(git -C "$SR" rev-parse refs/heads/vid-state/records)" = "$C" ] || fail 'a save with nothing changed pushed'
# GM-3 S2: a ref added under refs/vid/ with HEAD unchanged is saved: the bundle is made again, not reused, and the restore below holds it
VX=$(git commit-tree "HEAD^{tree}" -p HEAD -m 'a commit only a refs/vid ref holds'); git update-ref refs/vid/take-over/1 "$VX"
sh "$GS" state-save > "$T/out" 2>&1 || fail 'a save after a new refs/vid ref failed'; ! grep -q 'as saved' "$T/out" || fail 'a new refs/vid ref at the same HEAD was taken as saved'
sum() { (cd "$1/.vid" && find RUN-STATE.md budget metrics-events decide tw plans plan results -type f ! -name '*.html' 2>/dev/null | sort | xargs cksum); }
sum "$T/toy" > "$T/before"; H=$(git rev-parse HEAD); mkdir "$T/new"; cd "$T/new"; rm -rf "$T/toy"
sh "$GS" state-restore owner/code-spec > "$T/out" 2>&1 || fail 'state-restore failed'; sum "$T/new" > "$T/after"; cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" > "$T/out"; fail 'the records came back different'; }
[ "$(git rev-parse HEAD)" = "$H" ] && [ -f INVENTORY.md ] || fail "the project's history did not come back"; [ "$(git rev-parse -q --verify refs/vid/take-over/1 || true)" = "$VX" ] || fail 'the refs/vid ref added at the same HEAD did not come back'; [ -z "$(git config core.hooksPath || true)" ] || fail 'the restore into an empty folder set core.hooksPath'; [ -d .vid/spec.git ] && [ -d .vid/code ] || fail 'spec.git or code was not rebuilt'
RC=0; mkdir "$T/full"; (cd "$T/full"; echo x > f; sh "$GS" state-restore owner/code-spec) > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'an empty folder' "$T/out" || fail 'a restore over a full folder'
sh "$GS" state-restore > "$T/out" 2>&1 || fail 'a current folder was refused'; grep -q 'are current' "$T/out" || fail 'a current folder was restored'
cp -R "$T/new" "$T/old"; printf 'two\n' > .vid/decide/rows/ROW-001.txt; sh "$GS" state-save > "$T/out" 2>&1 || fail 'a later save failed'; cd "$T/old"; git config core.hooksPath elsewhere/hooks; sh "$GS" state-restore > "$T/out" 2>&1 || fail 'a folder behind did not catch up'; [ "$(cat .vid/decide/rows/ROW-001.txt)" = two ] || fail 'a folder behind stayed behind'
[ "$(git config core.hooksPath)" = elsewhere/hooks ] || fail "a restore into a folder behind the records changed its core.hooksPath to $(git config core.hooksPath || echo nothing)"
gh repo create owner/open-one > /dev/null; printf 'state-repo: owner/open-one\n' >> .vid/tw/settings; RC=0; sh "$GS" state-save > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'owner/open-one is not a private repository' "$T/out" || fail 'a public repository took the records'
mkdir "$T/e2"; RC=0; (cd "$T/e2"; sh "$GS" state-restore owner/open-one) > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'not a private repository' "$T/out" || fail 'records were read from a public repository'
exit 0
