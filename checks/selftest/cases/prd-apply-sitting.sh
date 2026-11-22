#!/bin/sh
# Purpose: selftest case — a sitting's rulings applied by one writer (FB-1 A2). On the 0.9.4 good fixture before its final
# ratification (its `final` Ratifications line taken out), one edits file of the sitting's operations — a new answer and
# a ViD decision (`row`), an item restated whole (`row`), a mechanism row restated (`row`: the writer runs the court
# plainly, never with --before, so a mechanism ruling is not refused), a field set and a field dropped (`field`), the
# carrier resolved (`resolve`), the decisions labelled (`shown pause-2`, the label the court's own sum, the cksum of the
# A: text) and a Ratifications line (`ratified`) — leaves PRD.md exactly the fixture with those rows and lines changed,
# and the court green. A second file adds a row after another (`after`) and edits the thesis (`text`); a third drops the
# added row (`drop`), each leaving exactly that change; a fourth sets
# an answer's `Q:` field (`field`: a label may hold upper case, as the ledger's Q: and A: do). Env: CHECKS.
set -eu
fail() { echo "prd-apply-sitting: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
[ -f "$CHECKS/prd-apply.sh" ] || fail 'checks/prd-apply.sh is missing: no writer applies a sitting'
sed '/^- .* — final — /d' "$CHECKS/selftest/fixtures/prd-094-good.md" > PRD.md
sh "$CHECKS/prd.sh" PRD.md >/dev/null 2>&1 || fail 'the fixture without its final line is not court-green'
cp PRD.md before.md
A10='A-010 | human | 2026-08-28 | Q: should the send hour be configurable per subscriber? | A: yes — each subscriber picks the hour | settles: REQ-020'
A11T='no — the footer carries the address alone'
A11="A-011 | model_proposed | 2026-08-28 | Q: does the footer give support hours? | A: $A11T | settles: REQ-012"
R20='REQ-020 | functional | T1 | The digest send hour is configurable per subscriber. | fail-if: a subscriber'"'"'s chosen send hour is ignored | serves: digests land when each subscriber actually reads mail | authority: authoritative | source: thesis, A-010 | phase: later | feature: FEAT-01'
M01='MECH-01 | G1 | Feeds are polled on a schedule and normalised into one deduplicated listing store. | stated: seed "two source feeds, merged"'
printf 'row %s\nrow %s\nresolve OQ-1 A-010\nrow %s\nrow %s\nfield REQ-006 phase later\nfield REQ-005 cross-cutting\nshown pause-2\nratified gap answers 4444444\n' \
  "$A10" "$R20" "$A11" "$M01" > sitting.txt
sh "$CHECKS/prd-apply.sh" PRD.md sitting.txt --date 2026-08-28 > out.txt 2>&1 || { cat out.txt >&2; fail 'the sitting was refused'; }
SUM=$(printf '%s\n' "$A11T" | cksum | cut -d' ' -f1)
awk -v a10="$A10" -v a11="$A11 | shown: pause-2 $SUM" -v r20="$R20" -v m01="$M01" '
  /^REQ-005 / { sub(/ \| cross-cutting: ingest, digest-selection/, "") }
  /^REQ-006 / { sub(/\| phase: pilot \|/, "| phase: later |") }
  /^REQ-020 / { $0 = r20 }
  /^MECH-01 / { $0 = m01 }
  /^VID-QUESTION: \(OQ-1\) / { sub(/^VID-QUESTION: \(OQ-1\) /, "RESOLVED: (OQ-1) A-010 — ") }
  { print }
  /^A-009 / { print a10; print a11 }
  /^- 2026-08-28 — gap answers — 2222222$/ { print "- 2026-08-28 — gap answers — 4444444" }' before.md > want.md
cmp -s want.md PRD.md || { diff want.md PRD.md >&2 || true; fail 'the sitting left PRD.md other than its rows and lines'; }
sh "$CHECKS/prd.sh" PRD.md >/dev/null 2>&1 || fail 'the court is not green after the sitting'
sh "$CHECKS/prd.sh" PRD.md --pause 2>&1 | grep -q '^GAP  join 20' && fail 'shown pause-2 left a ViD decision unlabelled'
# after and text, then drop
cp PRD.md before.md
R13='REQ-013 | functional | T2 | Every digest footer names the hours the support address is read. | fail-if: a footer names no support hours | serves: a stuck subscriber knows when a person reads the mail | authority: authoritative | source: thesis | phase: pilot | feature: FEAT-03'
printf 'after REQ-012\nrow %s\nend\ntext\nJob seekers in niche trades who save a handful of targeted searches and\nread email daily.\n--\nJob seekers in skilled trades who save a handful of targeted searches and\nread email daily.\nend\n' "$R13" > two.txt
sh "$CHECKS/prd-apply.sh" PRD.md two.txt > out.txt 2>&1 || { cat out.txt >&2; fail 'after and text were refused'; }
awk -v r13="$R13" '{ sub(/^Job seekers in niche trades /, "Job seekers in skilled trades "); print } /^REQ-012 / { print r13 }' before.md > want.md
cmp -s want.md PRD.md || { diff want.md PRD.md >&2 || true; fail 'after and text left PRD.md other than the added row and the thesis line'; }
printf 'drop REQ-013\n' > three.txt
sh "$CHECKS/prd-apply.sh" PRD.md three.txt > out.txt 2>&1 || { cat out.txt >&2; fail 'drop was refused'; }
grep -v '^REQ-013 ' want.md > want2.md
cmp -s want2.md PRD.md || fail 'drop left PRD.md other than without the row'
# a field on an answer's Q: label (the ledger's Q: and A: are labels, upper case)
cp PRD.md before.md
printf 'field A-001 Q one digest for each saved search, or one combined digest?\n' > four.txt
sh "$CHECKS/prd-apply.sh" PRD.md four.txt > out.txt 2>&1 || { cat out.txt >&2; fail 'a field on an answer'"'"'s Q: was refused'; }
sed 's/^\(A-001 .*| \)Q: one digest per search or one combined? |/\1Q: one digest for each saved search, or one combined digest? |/' before.md > want.md
cmp -s want.md PRD.md || { diff want.md PRD.md >&2 || true; fail 'the field on Q: left PRD.md other than that field'; }
echo 'prd-apply-sitting: ok'
