#!/bin/sh
# Purpose: selftest case — four ticket-check rules (v0.26.10.12.3.1 A1-2 to
# A1-5). On TW's toy, S04's ticket quotes ROW-002 without its `owed: prerequisite` note; with a decision holding a .vid/
# path and an artifact link, an answer and a decision holding the owner's words, the writer quotes "(ViD's records)",
# "chosen by the owner", "confirmed by the owner" and the answer by its id, and the ticket passes the check. Refused by
# line and word in copies: the prerequisite note planted back; a .vid/ path and an artifact id; a named owner form in
# Decisions; a profanity. v0.26.10.12.3.2 (R2): ROW-002 (no "fails if") among the Faulted
# rows passes. Also:
# a pointer and a profanity in the title are refused; an artifact id with a full stop after it is rewritten and refused;
# a requirement statement's own quote, and in a decision a quote after "owners", "SLA: " or a key's "owner", stay.
# And: an AMENDED answer's named form is refused; "artifact" before an ordinary word (no digit) is no
# pointer. FIX-BATCH-T2 (OW-3): an answer whose last quoted reply holds a word of the list (A-305) is written with that
# word as "(a word)", and so is a law of CLAUDE.md holding one; the ticket passes, and its amendment, the law unchanged,
# does not say the laws it quotes changed. The cut (only the three named forms rewritten and refused): the lines A-177, A-090, A-175, D-056
# and D-042, toy-shaped, keep their other quotes and pass; a quote after the owner in no named form passes. v0.26.10.24.2: a
# quoted path into ViD's checks/ is rewritten and refused like the other pointers; a product's own path and plain words are not. FB-7 C5: an
# answer of two or three quoted replies is quoted whole, each left out, and the ticket passes; a quotation that is no answer, and one planted
# back, read as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-check-rules: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh
ck() { RC=0; sh "$W" check "$1" > "$T/out" 2>&1 || RC=$?; }
refused() { ck "$T/p.md"; [ "$RC" = 1 ] && grep -qF -- "$1" "$T/out" || fail "not refused: $1"; }
# the owner's words and ViD's records in a decision and an answer
sed -e 's/| A: cap at ten saved searches per subscriber for MVP | settles: REQ-006 | shown: pause-1 2042538/| A: "ten, final"; cap at ten saved searches per subscriber for MVP (owner chose "Ten" and "No more") | settles: REQ-006/' \
  -e 's/creating an eleventh is refused with the cap stated\./creating an eleventh is refused, and the account owner sees "10 of 10" above the list./' PRD.md > "$T/p" && cat "$T/p" > PRD.md
A177='A: REQ-006 and REQ-001 each add "except for a deleted subscriber: no mail is sent"'; A090='A: the list shows "You saved…" after a save'; A175='A: REQ-006'"'"'s state reads "saved (not yet sent)", and the count shows'
awk -v a="$A177" -v b="$A090" -v c="$A175" '/^REQ-006 / { sub(/source: A-005/, "source: A-005, A-177, A-090, A-175") } { print } /^A-005 / { print "A-177 | human | 2026-10-23 | Q: deleted? | " a "; owner: \"Yes, all recommended\" | settles: REQ-006"; print "A-090 | human | 2026-10-23 | Q: text? | " b " | settles: REQ-006"; print "A-175 | human | 2026-10-23 | Q: state? | " c " | settles: REQ-006" }' PRD.md > "$T/p" && cat "$T/p" > PRD.md
printf -- '- **D-005** REQ-006 the cap is ten, owner: "ten is plenty", as .vid/milestones-prelim.json and https://claude.ai/artifact/JTBFCZ4Y8xhDKzpgttPvAC say | why: cost | enforced: convention\n' >> DECISIONS.md
# FB-7 C5: an answer of two and of three quoted replies, beside A-005's one
sed 's/source: A-005, A-177/source: A-005, A-301, A-302, A-303, A-305, A-177/' PRD.md > "$T/p" && cat "$T/p" > PRD.md
printf '%s\n' 'A-301 | human | 2026-10-23 | Q: two? | A: "the first one"; "and the second"; the list holds both | settles: REQ-006' 'A-302 | human | 2026-10-23 | Q: three? | A: "one such"; "two such"; "three such"; the list holds the three | settles: REQ-006' \
  'A-303 | human | 2026-10-23 | Q: words? | A: the page says "one; two"; "three" follows | settles: REQ-006' \
  'A-305 | human | 2026-10-23 | Q: tone? | A: "Yes, as described (Recommended)"; "keep it damn simple" | settles: REQ-006' > "$T/a3"
awk -v f="$T/a3" '{ print } /^A-005 / { while ((getline l < f) > 0) print l }' PRD.md > "$T/p" && cat "$T/p" > PRD.md
D6='REQ-006 the message is "ten saved", as recorded in artifact JTBFCZ4Y8xhDKzpgttPvAC.'; D7='REQ-006 for owners the SLA: "99.9" and the "owner": "ops" key stay'
printf -- '- **D-006** %s | why: clarity | enforced: convention\n- **D-007** %s | why: product text | enforced: convention\n' "$D6" "$D7" >> DECISIONS.md
D8='REQ-006 the message is "Ask the owner!"; the action says "Save"'; printf -- '- **D-008** %s | why: product text | enforced: convention\n' "$D8" >> DECISIONS.md
D56='**D-056** REQ-006 the name confirmed by the owner as "Sparrow" | why: brand'; D42='**D-042** REQ-006 the cap holds | why: owner ("Ten it is", 2026-10-23)'
printf -- '- %s | enforced: convention\n- %s | enforced: convention\n' "$D56" "$D42" >> DECISIONS.md
printf -- '- **D-013** REQ-006 the row is counted by checks/extractors/invariant.cap.sh, as `checks/test.sh` runs it | why: cost | enforced: convention\n- **D-014** REQ-006 the product'"'"'s src/checks/cap.py runs the health checks/alarms. | why: cost | enforced: convention\n' >> DECISIONS.md
{ [ -f CLAUDE.md ] && cat CLAUDE.md; printf '\n## Import law\n\n- Every import crosses a seam the table declares, damn the shortcut.\n'; } > "$T/cl" && cat "$T/cl" > CLAUDE.md; g add CLAUDE.md
g commit -qam 'owner words and records planted'; tw_ratify 'Yes, with D-005' || fail 'the toy was not ratified again'
tw_skel || fail 'the skeleton round failed'; tw_closed S02; tw_closed S03; tw_start S04 || fail 'S04 was refused'
F=$(sh "$W" write step S04 2> "$T/werr") || fail "S04's ticket was refused"
grep -qxF '> ROW-002 | behavior | REQ-006 | anonymous | n/a | A subscriber can keep up to ten saved searches, and an eleventh is refused with a message that states the limit of ten. | REQ-006 | origin: REQ-006' "$F" || fail 'ROW-002 is not quoted without its prerequisite note'
grep -q 'owed: prerequisite' "$F" && fail 'a prerequisite note is written'
grep -qxF "> - **D-005** REQ-006 the cap is ten, confirmed by the owner, as (ViD's records) and (ViD's records) say | why: cost | enforced: convention" "$F" || fail 'the decision is not written in neutral words with its records hidden'
grep -qF '| A: cap at ten saved searches per subscriber for MVP (chosen by the owner) | settles: REQ-006' "$F" || fail 'the answer is not written in neutral words'
grep -qF '| A: the list holds both | settles: REQ-006' "$F" && grep -qF '| A: the list holds the three | settles: REQ-006' "$F" || fail 'an answer of several quoted replies is not written by its own words'
grep -qF '| A: the page says "one; two"; "three" follows | settles: REQ-006' "$F" || fail 'a quotation that is no reply is changed'
! grep -q 'the first one\|and the second\|two such\|three such' "$F" || fail 'a quoted reply reaches the ticket'
# FIX-BATCH-T2 (OW-3): an answer whose last reply holds a word of the list: that word blanked, as the export blanks it, and the ticket passes
grep -qF '| A: "keep it (a word) simple" | settles: REQ-006' "$F" || fail "the last reply's word of the list is not blanked: $(grep 'A-305' "$F" | head -n 1)"
grep -qF '> - Every import crosses a seam the table declares, (a word) the shortcut.' "$F" || fail "a law's word of the list is not blanked: $(grep 'Every import' "$F" | head -n 1)"
! grep -qi 'damn' "$F" || fail 'a word of the list reaches the ticket'
# and an amendment of the posted ticket, its laws unchanged, does not say the laws it quotes changed
cp "$F" "$T/s04.md"; cp "${F%.md}.meta" "$T/s04.meta"; tw_post step S04 || fail "S04's ticket could not be posted"; AM=$(sh "$W" write amend "$TW_N" 2> "$T/werr") || fail "the amendment of #$TW_N was refused"
! grep -q 'the laws it quotes changed' "$AM" "${AM%.md}.meta" || fail 'an unchanged law holding a word of the list reads as changed'
cp "$T/s04.md" "$F"; cp "$T/s04.meta" "${F%.md}.meta"
grep -q 'ten is plenty\|ten, final\|milestones-prelim\|claude\.ai' "$F" && fail "the owner's words or a pointer reach the ticket"
grep -qF '> - **D-006** REQ-006 the message is "ten saved", as recorded in (ViD'"'"'s records). | why: clarity' "$F" || fail 'an artifact id with a full stop after it is not rewritten'
grep -qF "| $A177; confirmed by the owner | settles: REQ-006" "$F" || fail "A-177's added clause is not kept, or its owner's words not rewritten"
for x in "$A090" "$A175" "> - $D56 |" "> - $D42 |"; do grep -qF -- "$x" "$F" || fail "a quote in no named form is changed: $x"; done
grep -qxF "> - **D-007** $D7 | why: product text | enforced: convention" "$F" || fail "a quote after owners, SLA: or a key's owner is left out"
grep -qF 'and the account owner sees "10 of 10" above the list.' "$F" || fail "a requirement statement's own quote is left out"
grep -qxF "> - **D-008** $D8 | why: product text | enforced: convention" "$F" || fail 'a quoted "owner" is taken for the owner'
grep -qxF "> - **D-013** REQ-006 the row is counted by (ViD's records), as \`(ViD's records)\` runs it | why: cost | enforced: convention" "$F" || fail 'a path into checks/ is not rewritten'
grep -qF "the product's src/checks/cap.py runs the health checks/alarms. | why" "$F" || fail "a product's own path or plain words are rewritten"
ck "$F"; [ "$RC" = 0 ] || fail "S04's ticket, ROW-002 in Rows among them, is refused"
grep -q '^- ROW-002' "$F" && ! sed -n '/^## Faulted rows$/,/^## /p' "$F" | grep -q 'ROW-002' || fail 'ROW-002 is not in Rows alone'
# planted, each refused by line and word
pl() { awk -v s="## $1" -v l="$2" '{ print } $0 == s { getline; print; print l }' "$F" > "$T/p.md"; cp "${F%.md}.meta" "$T/p.meta"; }
sed 's/^\(> ROW-002 | .*\) | origin: REQ-006$/\1 | owed: prerequisite — the harness holds none | origin: REQ-006/' "$F" > "$T/p.md"; refused 'a prerequisite note — ROW-002'
pl 'Faulted rows' "- ROW-002: make this row's fail-if true, and nothing else"; ck "$T/p.md"; [ "$RC" = 0 ] || fail 'a faulted row with no "fails if" is refused'
pl 'Decisions' '> - **D-009** REQ-006 as set down in .vid/plan/notes.md'; refused "a pointer into ViD's records — .vid/plan/notes.md"
pl 'Rules that bear on these rows' '> rule | RULE-009 | a rule | checks/extractors/invariant.x.sh | 1'; refused "a pointer into ViD's records — checks/extractors/invariant.x.sh"
pl 'Decisions' "> - **D-015** REQ-006 run by 'checks/test.sh'"; refused "a pointer into ViD's records — checks/test.sh"
pl 'Decisions' '> - **D-016** REQ-006 see [checks/census.sh](x) and **checks/test.sh**'; refused "a pointer into ViD's records — checks/census.sh"
pl 'History' '- see the owner page, artifact JTBFCZ4Y8xhDKzpgttPvAC'; refused "a pointer into ViD's records — artifact JTBFCZ4Y8xhDKzpgttPvAC"
pl 'Decisions' '> - **D-010** REQ-006 the cap, owner chose "ten" and "no more"'; refused 'an owner quote — owner chose "ten"'
pl 'Decisions' '> - **D-012** REQ-006 the cap, owner: "ten and no more"'; refused 'an owner quote — owner: "ten and no more"'
pl 'History' '- the earlier attempt was a bloody mess'; refused 'profanity — bloody'
pl 'Decisions' '> - **D-011** REQ-006 as recorded in artifact JTBFCZ4Y8xhDKzpgttPvAC.'; refused "a pointer into ViD's records — artifact JTBFCZ4Y8xhDKzpgttPvAC"
sed '1s/$/, artifact JTBFCZ4Y8xhDKzpgttPvAC/' "$F" > "$T/p.md"; refused "line 1: a pointer into ViD's records — artifact JTBFCZ4Y8xhDKzpgttPvAC"
sed '1s/$/, a bloody mess/' "$F" > "$T/p.md"; refused 'line 1: profanity — bloody'
pl 'Requirements' '> A-007 AMENDED | human | 2026-10-01 | Q: cap? | A: "ten is plenty"; ten | settles: REQ-006'; refused 'an owner quote — A: "ten is plenty"; '
pl 'Requirements' '> A-304 | human | 2026-10-01 | Q: cap? | A: "ten is plenty"; "or nine"; ten | settles: REQ-006'; refused 'an owner quote — A: "ten is plenty"; '
pl 'History' '- the deploy artifact, production-ready, is tagged'; ck "$T/p.md"; [ "$RC" = 0 ] || fail '"artifact" before an ordinary word is refused'
exit 0
