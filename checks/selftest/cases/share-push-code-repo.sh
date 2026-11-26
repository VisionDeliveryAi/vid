#!/bin/sh
# Purpose: selftest case — a share goes to a repository of its own (FIX-BATCH-T1 §11, B-8), on the share's toy and its fake gh,
# made-up names alone. A private repository of the login's whose main holds a product (app/main.py, README.md): share-push is
# refused, naming app/main.py, and main does not move; so are one holding code under projects/ (README.md and
# projects/app/main.py), one holding a run folder with no MANIFEST.json, and a code repository whose one branch is master (no
# main made in it). A private repository whose main holds a run folder with its MANIFEST.json and a README.md: the share
# is pushed beside them. An empty one: pushed, as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-push-code-repo: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T"; GS=checks/github.sh; BF=.vid/shares/2026-11-local-toy
seed() { # <repo> <path>…: main holds those files
  _r=$1; shift; _w=$T/seed.$$; rm -rf "$_w"; git init -q "$_w"
  for _p in "$@"; do mkdir -p "$_w/$(dirname "$_p")"; printf 'x\n' > "$_w/$_p"; done
  git -C "$_w" add -A && git -C "$_w" -c user.name=t -c user.email=t@example.invalid commit -qm seed && git -C "$_w" push -q "$(sh_dir "$_r")/remote.git" HEAD:refs/heads/main; }
sh_repo quill-tester/toy-product true; seed quill-tester/toy-product app/main.py README.md
G=$(sh_dir quill-tester/toy-product)/remote.git; C0=$(git --git-dir="$G" rev-parse main)
if sh "$GS" share-push --repo quill-tester/toy-product --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1; then fail 'a share was pushed onto a product repository'"'"'s main'; fi
grep -q 'holds more than shares (app/main.py)' "$T/out" || fail 'the refusal does not name the first other path'
[ "$(git --git-dir="$G" rev-parse main)" = "$C0" ] || fail 'main moved after the refusal'
# code under projects/: refused; a run folder without its MANIFEST.json: refused
for x in projects/app/main.py projects/x/y/z.py; do
  r=quill-tester/toy-$(printf '%s' "$x" | tr '/.' '--'); sh_repo "$r" true; seed "$r" README.md "$x"
  if sh "$GS" share-push --repo "$r" --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1; then fail "a main holding $x took the share"; fi
  grep -q "holds more than shares ($x)" "$T/out" || fail "the refusal does not name $x"
done
# a code repository with no main, its branch master: refused, no main made
sh_repo quill-tester/toy-master true; _w=$T/seedm; git init -q "$_w"; printf 'x\n' > "$_w/app.py"
git -C "$_w" add -A && git -C "$_w" -c user.name=t -c user.email=t@example.invalid commit -qm seed && git -C "$_w" push -q "$(sh_dir quill-tester/toy-master)/remote.git" HEAD:refs/heads/master
if sh "$GS" share-push --repo quill-tester/toy-master --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1; then fail 'a repository with branches but no main took the share'; fi
grep -q 'master' "$T/out" || fail 'the refusal does not name the branch'
git --git-dir="$(sh_dir quill-tester/toy-master)/remote.git" rev-parse -q --verify refs/heads/main > /dev/null && fail 'a main was made in the code repository'
sh_repo quill-tester/vid-shares true; seed quill-tester/vid-shares projects/old/2026-10-a/RUN.md projects/old/2026-10-a/MANIFEST.json "projects/old/2026-10-a/records/caf$(printf '\303\251').txt" README.md
sh "$GS" share-push --repo quill-tester/vid-shares --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1 || fail 'a share repository holding projects/ and README.md was refused'
git --git-dir="$(sh_dir quill-tester/vid-shares)/remote.git" cat-file -e main:projects/toy/2026-11-local-toy/RUN.md || fail 'the share is not on main'
sh_repo quill-tester/vid-shares-2 true
sh "$GS" share-push --repo quill-tester/vid-shares-2 --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1 || fail 'an empty repository was refused'
# a file name holding a line break: refused, never read as two harmless names
sh_repo quill-tester/toy-nl true; seed quill-tester/toy-nl README.md projects/old/2026-10-a/MANIFEST.json "$(printf '\nnotice.txt')" app/main.py
if sh "$GS" share-push --repo quill-tester/toy-nl --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1; then fail 'a main holding a file name with a line break took the share'; fi
grep -q 'holds more than shares' "$T/out" || fail 'the line-break refusal does not say why'
# the branches cannot be read: refused, nothing pushed
sh_repo quill-tester/toy-locked true; LK=$(sh_dir quill-tester/toy-locked)/remote.git; chmod 000 "$LK"
if sh "$GS" share-push --repo quill-tester/toy-locked --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1; then chmod 755 "$LK"; fail 'a repository whose branches cannot be read took the share'; fi
chmod 755 "$LK"
grep -q 'could not be read' "$T/out" || fail "the unreadable repository's refusal does not say why: $(cat "$T/out")"
git --git-dir="$LK" rev-parse -q --verify refs/heads/main > /dev/null && fail 'a main was made in the unreadable repository'
echo 'share-push-code-repo: ok'
