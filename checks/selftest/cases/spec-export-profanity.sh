#!/bin/sh
# Purpose: selftest case — the spec export blanks profanity (0.26.11.1.2, R7's export half). On tw-spec.sh's toy, the owner's words
# quoted in DECISIONS.md and PRD.md with a profane word in each, a design canvas holding one, a binary design file holding the same letters:
# spec-setup exports, nothing refused; the exported DECISIONS.md, PRD.md and the canvas hold "(a word)" where each profane word stood, and every
# other line and word as at ViD's HEAD (a word that only contains a listed one's letters, as "class" holds "ass", unchanged); the binary file
# and the files with no profane word are exported byte for byte; ViD's own files, index and refs are unchanged, but refs/vid/export, the export itself (FB-3 B2). The writer's word check is
# lib.sh's, the one list: writer.sh defines none of its own. A file whose name holds a quote (git quotes it unless asked for raw
# names) and whose one line, with no final newline, holds a listed word is exported blanked, under its own name, still with no final newline. A
# name ending in a tab, holding a listed word, is blanked under that name, no tab-less twin added; a name holding a \001 byte is refused, named. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "spec-export-profanity: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# one list: lib.sh's, which the writer uses
grep -q '^PROF=' "$CHECKS/lib.sh" || fail "lib.sh holds no word check"; ! grep -q 'function prof(' "$CHECKS/writer.sh" || fail 'writer.sh defines its own word check'
tw_toy "$T/toy"
GS=$CHECKS/github.sh; SR=$T/gh/repos/owner%code-spec/remote.git
printf '\nD-099 | the digest hour | 07:00 | why: owner ("Damn right, seven it is; no more of this shit.") | origin: answer\n' >> DECISIONS.md
printf '\nA first-class digest, as the owner put it: "a bloody good digest, the class of the field".\n' >> PRD.md
mkdir -p design/screens; printf '<html><body><p data-screen="HOME">Home — crap placeholder text, (damn) it</p></body></html>\n' > design/screens/HOME.dc.html
printf 'PNG\000\001shit\000\002' > design/screens/logo.png
printf 'a crap note' > 'design/screens/the "say" note.txt'   # a quote in the name, no final newline
TB=$(printf 'design/screens/tab\t'); printf 'more crap\n' > "$TB"   # a name ending in a tab
g add -A; g commit -qm 'the owner quoted'
IDX0=$(git ls-files -s | git hash-object --stdin); REFS0=$(git for-each-ref | git hash-object --stdin); H=$(git rev-parse HEAD)
RC=0; sh "$GS" spec-setup > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the export was refused ($RC)"
C1=$(git -C "$SR" rev-parse -q --verify refs/heads/main) || fail 'nothing was pushed'
x() { git -C "$SR" show "$C1:$1"; }
x DECISIONS.md > "$T/d"; x PRD.md > "$T/p"; x design/screens/HOME.dc.html > "$T/c"
# the profane words are gone from the copy
for f in d p c; do ! grep -qiwE 'damn|shit|bloody|crap' "$T/$f" || fail "the exported copy $f holds a profane word: $(grep -iwE 'damn|shit|bloody|crap' "$T/$f")"; done
grep -qxF 'D-099 | the digest hour | 07:00 | why: owner ("(a word) right, seven it is; no more of this (a word).") | origin: answer' "$T/d" || fail "the decision line is not the line with each profane word as (a word): $(grep '^D-099' "$T/d")"
grep -qxF 'A first-class digest, as the owner put it: "a (a word) good digest, the class of the field".' "$T/p" || fail "the PRD line: $(grep 'first-class' "$T/p")"
grep -qF '<p data-screen="HOME">Home — (a word) placeholder text, ((a word)) it</p>' "$T/c" || fail "the canvas: $(cat "$T/c")"
x "$TB" > "$T/tb" || fail 'the file whose name ends in a tab is not exported under its name'
[ "$(cat "$T/tb")" = 'more (a word)' ] || fail "the tab-ended name's copy is not blanked: $(cat "$T/tb")"
! git -C "$SR" cat-file -e "$C1:design/screens/tab" 2>/dev/null || fail 'the export added a tab-less twin of the tab-ended name'
x 'design/screens/the "say" note.txt' > "$T/q" || fail 'the file whose name holds a quote is not exported under its name'
[ "$(od -An -c "$T/q" | tr -d ' \n')" = 'a(aword)note' ] || fail "the quoted name's copy is not its one line blanked, with no final newline: $(od -An -c "$T/q" | tr -s ' ')"
# every other line as at HEAD
git show HEAD:DECISIONS.md | grep -v '^D-099 ' > "$T/d0"; grep -v '^D-099 ' "$T/d" > "$T/d1"; cmp -s "$T/d0" "$T/d1" || fail 'the export changed another line of DECISIONS.md'
git show HEAD:PRD.md | grep -v 'first-class digest' > "$T/p0"; grep -v 'first-class digest' "$T/p" > "$T/p1"; cmp -s "$T/p0" "$T/p1" || fail 'the export changed another line of PRD.md'
for f in design/screens/logo.png BASELINE.md ARCHITECTURE.md GRADING-CHECKLIST.md; do [ "$(git -C "$SR" rev-parse "$C1:$f")" = "$(git rev-parse "HEAD:$f")" ] || fail "the export changed $f"; done
# the project's own files untouched
[ "$(git ls-files -s | git hash-object --stdin)" = "$IDX0" ] && [ "$(git for-each-ref | grep -v '	refs/vid/export$' | git hash-object --stdin)" = "$REFS0" ] && [ -z "$(git status --porcelain)" ] || fail "the export changed ViD's index, refs or working tree"
grep -q 'shit' DECISIONS.md && grep -q 'bloody' PRD.md || fail "the export changed the project's files"
grep -q "^export $C1 from=$H state=pushed at=" .vid/tw/log || fail 'the export is not logged'
# a name holding a \001 byte: refused, named, nothing pushed
O1=$(printf 'design/screens/one\001two.txt'); printf 'a note\n' > "$O1"; g add -A; g commit -qm 'a name with a 001 byte'
RC=0; sh "$GS" spec-export > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a name holding a 001 byte was exported'
grep -qF "$O1" "$T/out" && grep -q 'refused' "$T/out" || fail "the refusal does not name the file holding a 001 byte: $(cat "$T/out")"
[ "$(git -C "$SR" rev-parse refs/heads/main)" = "$C1" ] || fail 'the refused export pushed'
exit 0
