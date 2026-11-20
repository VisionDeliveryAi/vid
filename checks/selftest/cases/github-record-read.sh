#!/bin/sh
# Purpose: selftest case — github.sh record-read, the read of a record the owner names by its GitHub link (IR I1, its case
# github-record-read). On the fake gh: a pull request that adds one Markdown file, changes another, deletes a third and changes a
# text file; record-read of its link prints, in path order, one `record:` line each for the two Markdown files at the pull
# request's head commit (the blob link there) and each file's text as it stands at that head, the deleted file and the text file
# left out. A blob link at a commit prints that file at that commit. A blob link at a branch name, a link that is neither form,
# and a pull request with no Markdown file are refused. It writes nothing anywhere: the fake's call log holds reads alone (gh auth
# status and GETs of the pull request, its files and the files' contents, no method, no field), its write log stays empty, and no
# file under ViD's repository changes, a stranded .vid/.old.<pid>.<name> folder included (github.sh's start-up recovery is not
# record-read's). A pull request's file names needing an escape in the address (%, a space, #, ?) are each read escaped, in the
# contents call and the record's link; when a later file's read fails, nothing is printed, the file read before it included. A blob link whose path holds `?` or `#` (a line permalink, ?plain=1#L3) is refused and calls nothing. A pull
# request's file names are never expanded as patterns: `records/[a].md` is read as itself while the working tree holds records/a.md. In
# GitHub manual it refuses, exit 1, naming the owner's copy, and calls nothing; so does a run from a subfolder of ViD's repository,
# where the mode cannot be read. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "github-record-read: $*" >&2; cat "$T/out" "$T/err" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/v"; cd "$T/v"; tk_code; rm -rf .vid; gh_fake
# the team's code repository: main with two records and a text file, then a branch that changes them
( cd "$T/dev" && mkdir -p records && printf '# The feed\n\nThe feed is read once a day.\n' > records/feed.md && printf '# Old\n\nGone soon.\n' > records/old.md && printf 'notes\n' > notes.txt &&
  g add -A && g commit -qm 'the records' && git push -q origin main 2>/dev/null ) || fail 'the code repository could not be set up'
M1=$(git -C "$T/dev" rev-parse HEAD)
( cd "$T/dev" && git checkout -q -b rec && printf '# The feed\n\nThe feed is read every hour, in order.\n' > records/feed.md && printf '# A decision\n\nThe writer owns the table.\n' > records/write-path.md &&
  git rm -q records/old.md && printf 'more notes\n' > notes.txt && g add -A && g commit -qm 'the record' && git push -q origin rec 2>/dev/null ) || fail 'the branch could not be made'
H=$(git -C "$T/dev" rev-parse HEAD)
P=$(gh pr create -R owner/code --head rec --base main --title 'A decision record' --body 'the record' | sed 's#.*/##')
( cd "$T/dev" && git checkout -q main && git checkout -q -b txt && printf 'other\n' > notes.txt && g add -A && g commit -qm 'text only' && git push -q origin txt 2>/dev/null ) || fail 'the text branch could not be made'
P2=$(gh pr create -R owner/code --head txt --base main --title 'Text only' --body 'no record' | sed 's#.*/##')
( cd "$T/dev" && git checkout -q main && git checkout -q -b brk && printf '# Bracket\n\nRead as itself.\n' > 'records/[a].md' && g add -A && g commit -qm 'a bracket name' && git push -q origin brk 2>/dev/null ) || fail 'the bracket branch could not be made'
HB=$(git -C "$T/dev" rev-parse HEAD); P3=$(gh pr create -R owner/code --head brk --base main --title 'A bracket name' --body 'brackets' | sed 's#.*/##')
# names that need each escape in the address (%, a space, #, ?); and a pull request whose second file's read fails
( cd "$T/dev" && git checkout -q main && git checkout -q -b esc && for n in 'a%20b' 'x y' 'h#1' 'q?'; do printf '# %s\n' "$n" > "records/$n.md"; done && g add -A && g commit -qm 'names to escape' && git push -q origin esc 2>/dev/null ) || fail 'the escape branch could not be made'
HE=$(git -C "$T/dev" rev-parse HEAD); P4=$(gh pr create -R owner/code --head esc --base main --title 'Names to escape' --body 'escapes' | sed 's#.*/##')
( cd "$T/dev" && git checkout -q main && git checkout -q -b two && printf '# Read\n' > records/a-read.md && printf '# Fails\n' > records/z-fails.md && g add -A && g commit -qm 'two records' && git push -q origin two 2>/dev/null ) || fail 'the two-record branch could not be made'
P5=$(gh pr create -R owner/code --head two --base main --title 'Two records' --body 'two' | sed 's#.*/##')
mkdir "$T/wrap"; printf '#!/bin/sh\ncase "$*" in *contents/records/z-fails.md*) echo "HTTP 502" >&2; exit 1 ;; esac\nexec "%s/bin/gh" "$@"\n' "$T" > "$T/wrap/gh"; chmod +x "$T/wrap/gh"
# ViD's repository, in GitHub auto
mkdir -p .vid/plan; git init -q; printf '# spec\n' > PRD.md; g add PRD.md && g commit -qm 'the spec'
printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="auto" words="auto" at=2026-11-19T09:00:00Z\n' > .vid/plan/setup
mkdir -p records .vid/.old.4242.decide; printf 'a\n' > records/a.md; printf 'stranded\n' > .vid/.old.4242.decide/x   # a pattern's match, and a stranded folder
snap() { find . -type f | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; }
snap > "$T/before"; : > "$FAKEGH/log"; gh_wclear
rr() { RC=0; sh "$CHECKS/github.sh" record-read "$1" > "$T/out" 2> "$T/err" || RC=$?; }
# the pull request: its two Markdown files, at its head, in path order
rr "https://github.com/owner/code/pull/$P"; [ "$RC" = 0 ] || fail "the pull request's read failed ($RC)"
[ -d .vid/.old.4242.decide ] && [ ! -e .vid/decide ] || fail 'record-read moved a stranded .vid/.old folder'
printf 'record: https://github.com/owner/code/blob/%s/records/feed.md\n# The feed\n\nThe feed is read every hour, in order.\n\nrecord: https://github.com/owner/code/blob/%s/records/write-path.md\n# A decision\n\nThe writer owns the table.\n\n' "$H" "$H" > "$T/want"
cmp -s "$T/want" "$T/out" || { diff "$T/want" "$T/out" >&2 || :; fail 'the pull request read is not its two Markdown files at its head, in path order'; }
# a blob link at a commit: that file at that commit
rr "https://github.com/owner/code/blob/$M1/records/feed.md"; [ "$RC" = 0 ] || fail "the blob read failed ($RC)"
printf 'record: https://github.com/owner/code/blob/%s/records/feed.md\n# The feed\n\nThe feed is read once a day.\n\n' "$M1" > "$T/want"
cmp -s "$T/want" "$T/out" || { diff "$T/want" "$T/out" >&2 || :; fail 'the blob read is not the file at its commit'; }
# a pull request's names are read as themselves, never as patterns
rr "https://github.com/owner/code/pull/$P3"; [ "$RC" = 0 ] || fail "the bracket name's read failed ($RC)"
printf 'record: https://github.com/owner/code/blob/%s/records/[a].md\n# Bracket\n\nRead as itself.\n\n' "$HB" > "$T/want"
cmp -s "$T/want" "$T/out" || { diff "$T/want" "$T/out" >&2 || :; fail 'records/[a].md was not read as itself'; }
# each name escaped for the address: %25, %20, %23, %3F, in the contents call and the record's link, its text read
rr "https://github.com/owner/code/pull/$P4"; [ "$RC" = 0 ] || fail "the escaped names' read failed ($RC)"
for q in a%2520b h%231 q%3F x%20y; do n=$(printf '%s' "$q" | sed 's/%20/ /; s/%23/#/; s/%3F/?/; s/%25/%/'); printf 'record: https://github.com/owner/code/blob/%s/records/%s.md\n# %s\n\n' "$HE" "$q" "$n"
  grep -qxF "gh api repos/owner/code/contents/records/$q.md?ref=$HE --jq .content | @base64d" "$FAKEGH/log" || fail "no contents call for records/$q.md: $(grep contents "$FAKEGH/log" | tail -n 4)"; done > "$T/want"
cmp -s "$T/want" "$T/out" || { diff "$T/want" "$T/out" >&2 || :; fail 'the names needing escapes were not read, each escaped in its address and link'; }
# a later file's read fails: refused, and nothing printed, the first file's record included
RC=0; PATH="$T/wrap:$PATH" sh "$CHECKS/github.sh" record-read "https://github.com/owner/code/pull/$P5" > "$T/out" 2> "$T/err" || RC=$?
[ "$RC" = 1 ] && grep -q 'records/z-fails.md' "$T/err" || fail "a pull request whose second read failed was not refused ($RC)"
[ ! -s "$T/out" ] || fail "a failed read printed a record: $(head -n 1 "$T/out")"
# a line permalink: refused, nothing called
L0=$(grep -c . "$FAKEGH/log"); rr "https://github.com/owner/code/blob/$M1/records/feed.md?plain=1#L3"; [ "$RC" = 1 ] && grep -q 'refused' "$T/err" || fail "a blob link with ?plain=1#L3 was not refused ($RC)"
[ "$(grep -c . "$FAKEGH/log")" = "$L0" ] || fail "a refused permalink called gh: $(tail -n 1 "$FAKEGH/log")"
# refused: a blob link at a branch, a link of no form, a pull request with no Markdown file
rr 'https://github.com/owner/code/blob/main/records/feed.md'; [ "$RC" = 1 ] && grep -q 'refused' "$T/err" || fail "a blob link at a branch was not refused ($RC)"
rr 'https://example.invalid/owner/code/pull/1'; [ "$RC" = 1 ] && grep -q 'refused' "$T/err" || fail "a link of no form was not refused ($RC)"
rr "https://github.com/owner/code/pull/$P2"; [ "$RC" = 1 ] && grep -q 'no Markdown file' "$T/err" || fail "a pull request with no Markdown file was not refused ($RC)"
# nothing written: reads alone in the call log, no write, no file of ViD's repository changed
[ -s "$FAKEGH/log" ] || fail 'record-read called nothing'
B=$(grep -vxF 'gh auth status' "$FAKEGH/log" | grep -vE '^gh api repos/owner/code/(pulls/[0-9]+|pulls/[0-9]+/files|contents/[^ ]+[?]ref=[0-9a-f]{40}) (--paginate )?--jq ' || true)
[ -z "$B" ] || fail "a call that is no read: $(printf '%s\n' "$B" | head -n 1)"
! grep -qE ' (-X|-f|-F|--method|--input|--field|--raw-field) ' "$FAKEGH/log" || fail "a call with a method or a field: $(grep -E ' (-X|-f|-F) ' "$FAKEGH/log" | head -n 1)"
[ ! -s "$FAKEGH/writes" ] || fail "record-read wrote to GitHub: $(head -n 1 "$FAKEGH/writes")"
snap > "$T/after"; cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2 || :; fail "a file under ViD's repository changed"; }
# GitHub manual: refused, the owner's copy named, nothing called
printf 'setup-answered key=github-mode value="manual" words="manual" at=2026-11-19T10:00:00Z\n' >> .vid/plan/setup; : > "$FAKEGH/log"
rr "https://github.com/owner/code/pull/$P"; [ "$RC" = 1 ] || fail "record-read in GitHub manual was not refused ($RC)"
grep -q "copy" "$T/err" && grep -q "ViD's repository" "$T/err" || fail "the refusal does not name the owner's copy: $(cat "$T/err")"
[ ! -s "$T/out" ] && [ ! -s "$FAKEGH/log" ] || fail "record-read in GitHub manual printed or called something: $(cat "$FAKEGH/log")"
# from a subfolder, where neither the mode nor ViD's records can be read: refused, nothing called
( cd records && RC=0; sh "$CHECKS/github.sh" record-read "https://github.com/owner/code/pull/$P" > "$T/out" 2> "$T/err" || RC=$?; [ "$RC" = 1 ] ) || fail 'record-read from a subfolder was not refused'
[ ! -s "$T/out" ] && [ ! -s "$FAKEGH/log" ] || fail "record-read from a subfolder printed or called something: $(cat "$FAKEGH/log")"
exit 0
