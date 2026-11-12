#!/bin/sh
# Purpose: selftest case — the share's send (0.26.10.28.7, R6), on the share's toy and its fake gh, made-up names alone. share-create
# makes the repository in the login's own account, --private; share-push puts the bundle at projects/<project>/<run>/ on main,
# authored and committed as ViD <vid@export.invalid>, neither git config's person nor the environment's; a run folder already
# there is not overwritten; a bundle holding a link is refused, and an owner written in other letter cases is still the login's; a
# bundle holding a value planted after its scan (the stand-in scanner) is refused with no call after
# gh auth status and no push; with no one to invite, nothing is invited. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-send: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T"; GS=checks/github.sh; R=quill-tester/vid-shares; BF=.vid/shares/2026-11-local-toy
sh "$GS" share-create --repo "$R" > "$T/out" 2>&1 || fail 'share-create failed'
grep -qx "gh repo create $R --private" "$SHAREGH/log" || fail 'the repository was not made --private in the login'"'"'s account'
[ "$(cat "$(sh_dir "$R")/private")" = true ] || fail 'the repository is not private'
sh "$GS" share-push --repo "$R" --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1 || fail 'share-push failed'
G=$(sh_dir "$R")/remote.git
git --git-dir="$G" cat-file -e main:projects/toy/2026-11-local-toy/RUN.md 2>/dev/null || fail 'the bundle is not at projects/toy/2026-11-local-toy/'
[ "$(git --git-dir="$G" log -1 --format='%an <%ae>|%cn <%ce>' main)" = 'ViD <vid@export.invalid>|ViD <vid@export.invalid>' ] || fail "the share commit is not ViD's fixed identity: $(git --git-dir="$G" log -1 --format='%an <%ae>|%cn <%ce>' main)"
! git --git-dir="$G" log --format='%an %ae %cn %ce %B' main | grep -qiE 'jane|example\.org' || fail "a person's name or address is in the share commit"
# a run folder already there is never overwritten
C0=$(git --git-dir="$G" rev-parse main); printf 'changed\n' >> "$BF/RUN.md"
if sh "$GS" share-push --repo "$R" --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1; then fail 'a run folder already there was overwritten'; fi
grep -q 'never overwritten' "$T/out" && [ "$(git --git-dir="$G" rev-parse main)" = "$C0" ] || fail 'the refusal is not said, or main moved'
# a value planted after the scan: refused, no call after gh auth status, nothing pushed
echo 'key PLANTED-VALUE' >> "$BF/records/round.log"; sh_mark
if sh "$GS" share-push --repo "$R" --project toy --run 2026-11-other "$BF" > "$T/out" 2>&1; then fail 'a bundle with a value left was pushed'; fi
[ "$(sh_calls | paste -sd '|' -)" = 'gh auth status' ] || fail "the refused push called more than gh auth status: $(sh_calls | paste -sd '|' -)"
grep -q 'records/round.log: kind planted' "$T/out" && ! grep -q 'key PLANTED' "$T/out" || fail 'the refusal does not name the file and the kind, or prints the value'
[ "$(git --git-dir="$G" rev-parse main)" = "$C0" ] || fail 'main moved after a refused push'
# a link in the bundle: refused before any call but gh auth status, nothing pushed
sed -i.b '/PLANTED-VALUE/d' "$BF/records/round.log"; rm -f "$BF/records/round.log.b"; ln -s ../RUN.md "$BF/records/note"; sh_mark
if sh "$GS" share-push --repo "$R" --project toy --run 2026-11-link "$BF" > "$T/out" 2>&1; then fail 'a bundle holding a link was pushed'; fi
[ "$(sh_calls | paste -sd '|' -)" = 'gh auth status' ] && grep -q 'holds a link' "$T/out" && [ "$(git --git-dir="$G" rev-parse main)" = "$C0" ] || fail 'a link was not refused before any call'
rm "$BF/records/note"
# an owner named in other letter cases is the login's own account
sh "$GS" share-create --repo Quill-Tester/vid-shares > "$T/out" 2>&1 || fail "the login's own account in other letter cases was refused: $(cat "$T/out")"
# no one invited: no invitation call
! grep -q 'collaborators/' "$SHAREGH/log" || fail 'an invitation call was made with no one named'
echo 'share-send: ok'
