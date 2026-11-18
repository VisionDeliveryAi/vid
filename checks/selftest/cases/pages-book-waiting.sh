#!/bin/sh
# Purpose: selftest case — what waits on the owner, in the book's margin (usability, B13). The panel's `face.sh
# waiting` (its spec's P9) is stood in for (fixtures/pages-toy.sh pg_face: a copy of checks/ whose face.sh prints a
# fixed sitting, or nothing). On the full pages' toy with a sitting waiting at stop 4 (the gaps) over four items — a
# requirement, a feature, a quality, and a pair of near-duplicates joined by `~` — the book shows "Waiting on you" on
# the product's line of the spine, the note "Waiting on you: The gaps, 4 items. Answer in the panel or in the chat." at
# the top of that chapter, and a mark beside each entry an item names, both of the pair, and on nothing else; the
# chapter is its page but for the note and the marks; nothing in the book can send or record an answer. A sitting at
# stop 8 marks the tests' chapter. When the sitting ends (nothing printed), and when face.sh has no `waiting` (it
# fails), the next book has no note and no mark. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-book-waiting: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
pg_face "$T/ck"; S=$T/ck/pages.sh; P=.vid/pages
pg_full "$T/toy"
chap() { awk -v n="{chapter: $1}" '$0 == n { on = 1; next } on && /^\{chapter: [0-9]+\}$/ { exit } on' "$P/BOOK.md"; }
printf 'pause-2\t4\tThe gaps\nREQ-002\tthe unsubscribe within a day\nFEAT-01\tthe daily digest\nDIM-consent\tconsent\nREQ-005~REQ-006\ttwo rules that may say the same\n' > "$T/ck/waiting"
sh "$S" all > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'all with a sitting waiting failed'; }
grep -qxF -- '- [The product](#chapter-2) — Waiting on you' "$P/BOOK.md" || fail 'the spine does not say the product waits on you'
[ "$(grep -c '— Waiting on you$' "$P/BOOK.md")" = 1 ] || fail 'another chapter is said to wait on you'
C=$(chap 2)
[ "$(printf '%s\n' "$C" | sed -n 2p)" = '!!! Waiting on you: The gaps, 4 items. Answer in the panel or in the chat.' ] || fail 'the note is not at the top of the chapter'
[ "$(grep -c '^!!! Waiting on you' "$P/BOOK.md")" = 1 ] || fail 'the note is in more than one place'
printf '%s\n' "$C" | grep -F '{!}' > "$T/m"
[ "$(grep -c . "$T/m")" = 5 ] || fail "not five marks: $(grep -c . "$T/m")"
for i in REQ-002 FEAT-01 DIM-consent REQ-005 REQ-006; do grep -F "{id: $i} {!}" "$T/m" > /dev/null || fail "$i is not marked"; done
[ "$(grep -c '{!}' "$P/BOOK.md")" = 5 ] || fail 'a mark is outside the waiting chapter'
# the chapter is its page but for the note and the marks
printf '%s\n' "$C" | grep -v '^!!! Waiting on you' | sed 's/ {!}//g' | grep -v '^As of ' > "$T/c"; grep -v '^As of ' "$P/PRD.md" > "$T/p"
cmp -s "$T/c" "$T/p" || fail 'the chapter differs from its page in more than the note and the marks'
grep -qF 'Waiting on you' "$P/PRD.md" && fail 'the page itself carries the note'
# nothing in the book answers
grep -qiE '<input|<textarea|<form|copy answers' "$P/BOOK.html" && fail 'a control in the book can send or record an answer'
grep -qF '<span class="mark"' "$P/BOOK.html" && grep -qF '<div class="note">Waiting on you: The gaps, 4 items.' "$P/BOOK.html" || fail 'the note and the marks are not drawn'
# a sitting at stop 8: the tests' chapter
printf 'test-list\t8\tThe test list\nROW-018\twaits on your decision\n' > "$T/ck/waiting"
sh "$S" book > "$T/out" 2>&1 || fail 'book at stop 8 failed'
grep -qxF -- '- [The tests](#chapter-5) — Waiting on you' "$P/BOOK.md" && chap 5 | grep -qxF '!!! Waiting on you: The test list, 1 items. Answer in the panel or in the chat.' || fail 'a sitting at stop 8 does not wait in the tests'
chap 5 | grep -qF '{id: ROW-018} {!}' || fail 'the test waiting is not marked'
# the sitting ended: no note, no mark
rm "$T/ck/waiting"; sh "$S" book > "$T/out" 2>&1 || fail 'book after the sitting failed'
grep -qE 'Waiting on you|\{!\}' "$P/BOOK.md" && fail 'the note or a mark outlives the sitting'
# a face.sh without waiting: no sitting read
printf '#!/bin/sh\nexit 2\n' > "$T/ck/face.sh"; sh "$S" book > "$T/out" 2>&1 || fail 'book with a face.sh that cannot say what waits failed'
grep -qE 'Waiting on you|\{!\}' "$P/BOOK.md" && fail 'a failing face.sh still marks the book'
printf '#!/bin/sh\nprintf "pause-2\\t4\\tThe gaps\\nREQ-002\\tx\\n"; exit 1\n' > "$T/ck/face.sh"; sh "$S" book > "$T/out" 2>&1 || fail 'book with a face.sh that prints and fails failed'
grep -qE 'Waiting on you|\{!\}' "$P/BOOK.md" && fail 'what a failing face.sh printed is read as a sitting'
printf '#!/bin/sh\necho "usage: face.sh write|end|standing"\n' > "$T/ck/face.sh"; sh "$S" book > "$T/out" 2>&1 || fail 'book with a face.sh printing another form failed'
grep -qE 'Waiting on you|\{!\}' "$P/BOOK.md" && fail 'a line not in the waiting form is read as a sitting'
exit 0
