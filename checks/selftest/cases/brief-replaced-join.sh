#!/bin/sh
# Purpose: selftest case — a marked line brings its replacement wherever it is quoted (IR I3). Two toys. The brief
# writer's: D-401 bears on ROW-104; D-402, labelled for another row, replaces part of it and cites none of its ids; D-403
# is joined on its own. Before the mark, the builder's brief of S2 lacks D-402. Once D-401 carries `| replaced-by:
# D-402, D-403`, the builder's brief, a fixer's and a grader's each quote D-401 with its mark, then D-402, then D-403,
# each once (a grader the rule parts, the line up to ' | why:', the mark included), and the check says ok. The ticket
# writer's: S02's open ticket (#2) quotes D-005, which bears on one of its rows, and D-007; D-006, labelled for a row of
# another step, replaces part of D-005. Nothing is owed until D-005 gains its mark; then, the spec exported as every
# changed spec is, writer.sh due owes amend 2, and the amendment's Decisions quote D-005 with its mark, then D-006, then
# D-007, each once. A chain: D-402 is marked by D-404 and D-006 by D-008, neither joining the rows on its own; each brief
# (the grader's rule text included) and the ticket quote it once, right after the line it replaces. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-replaced-join: $*" >&2; cat "$T/wout" "$T/due" "$T/werr" >&2 2>/dev/null; exit 1; }
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
rule() { l=$(dline "$1"); printf '%s\n' "${l%% | why:*}"; }
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
# ids <file>: the D-ids its decision lines start with, in order, one a line
ids() { sed -n 's/^\(> \)*- \*\*\(D-[0-9]*\)\*\*.*/\2/p' "$1" | tr '\n' ' '; }
bw_plugin; bw_repo "$T/repo"; bw_builder
cat >> DECISIONS.md <<'DEC'
- **D-401** a deletion asks once, in one sentence | why: one voice | enforced: convention | applies-to: ROW-104
- **D-402** a deletion asks in a dialog that names the link | why: a sentence alone was missed | enforced: convention | applies-to: ROW-101
- **D-403** a deletion's dialog offers no undo | why: the code is gone | enforced: convention | applies-to: ROW-104
- **D-404** a deletion's dialog names the link by its code | why: titles repeat | enforced: convention | applies-to: ROW-101
DEC
g commit -qam 'decisions'
mkdir -p .vid/ledger-results; S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief before the mark'
sec3 "$(bw_out)" | grep -q '\*\*D-402\*\*' && fail 'D-402 reached the builder before any mark (the toy does not test the mark)'
sed 's#^\(- \*\*D-401\*\* a deletion asks once, in one sentence\) | why:#\1 | replaced-by: D-402, D-403 | why:#' DECISIONS.md > D.x && cat D.x > DECISIONS.md && rm D.x
sed 's#^\(- \*\*D-402\*\* a deletion asks in a dialog that names the link\) | why:#\1 | replaced-by: D-404 | why:#' DECISIONS.md > D.x && cat D.x > DECISIONS.md && rm D.x
g commit -qam 'D-401 and D-402 marked'
S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
# seq <sec3 file> <how: dline|rule>: D-401, D-402, D-403 in a row, each once
seq3() { o=$(ids "$1" | tr ' ' '\n' | grep -E '^D-40[123]$' | tr '\n' ' '); [ "$o" = 'D-401 D-402 D-403 ' ] || fail "$3: the replaced line and its replacements are not quoted in order, once each: $o"
  for d in D-401 D-402 D-403; do grep -qxF -- "$($2 $d)" "$1" || fail "$3 lacks $d as $2"; done
  awk '/\*\*D-401\*\*/ { getline n; print n; exit }' "$1" | grep -q '^- \*\*D-402\*\*' || fail "$3: D-402 does not follow D-401"
  # the chain: D-402's own mark brings D-404, which joins no row on its own, once, right after D-402
  o=$(ids "$1" | tr ' ' '\n' | grep -E '^D-40[1234]$' | tr '\n' ' '); [ "$o" = 'D-401 D-402 D-404 D-403 ' ] || fail "$3: the chain D-401, D-402, D-404 is not quoted in order, once each: $o"
  grep -qxF -- "$($2 D-404)" "$1" || fail "$3 lacks D-404 as $2"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok on the builder brief'
sec3 "$(bw_out)" > "$T/b"; seq3 "$T/b" dline 'the builder brief'
grep -qF 'replaced-by: D-402, D-403' "$T/b" || fail 'the builder brief lacks the mark'
bw_write --role fixer --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the fixer brief'
sec3 "$(bw_out)" > "$T/f"; seq3 "$T/f" dline 'the fixer brief'
bw_write --role grader --slice 2 --rows ROW-104 --receipt "$S.full.xml" || fail 'the writer refused the grader brief'
grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok on the grader brief'
sec3 "$(bw_out)" > "$T/g"; seq3 "$T/g" rule 'the grader brief'
grep -qF 'D-401** a deletion asks once, in one sentence | replaced-by: D-402, D-403' "$T/g" || fail "the grader lacks D-401's mark"
grep -qF ' | why:' "$T/g" && fail 'the grader got more than the rule parts'
# the ticket writer's toy
cd "$T"; T0=$T; T=$T0/tw; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
cat >> DECISIONS.md <<'DEC'
- **D-005** a job read from two feeds is merged by its title alone | why: one listing | enforced: convention | applies-to: ROW-005
- **D-006** a job read from two feeds is merged by its title and its employer | why: titles repeat across employers | enforced: convention | applies-to: ROW-017
- **D-007** a merged job keeps the first feed's link | why: one source page | enforced: convention | applies-to: ROW-001
- **D-008** a job read from two feeds is merged by its title, its employer and its place | why: employers repeat across cities | enforced: convention | applies-to: ROW-017
DEC
g commit -qam 'decisions'
tw_skel || fail 'the skeleton round failed'
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; [ "$TW_N" = 2 ] || fail "S02's ticket is #$TW_N"
sec "$TW_F" Decisions > "$T/d0"; ! grep -q 'D-006' "$T/d0" || fail 'D-006 joined S02 before any mark (the toy does not test the mark)'
sh "$GS" tw-sync > /dev/null 2>&1
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; ! grep -qx 'amend 2' "$T/due" || fail 'S02 owes an amendment before the mark'
sed 's#^\(- \*\*D-005\*\* a job read from two feeds is merged by its title alone\) | why:#\1 | replaced-by: D-006, D-007 | why:#' DECISIONS.md > D.x && cat D.x > DECISIONS.md && rm D.x
sed 's#^\(- \*\*D-006\*\* a job read from two feeds is merged by its title and its employer\) | why:#\1 | replaced-by: D-008 | why:#' DECISIONS.md > D.x && cat D.x > DECISIONS.md && rm D.x
g commit -qam 'D-005 and D-006 marked'
sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; grep -qx 'amend 2' "$T/due" || fail 'a newly marked line quoted by an open ticket owes no amendment'
tw_post amend 2 || fail 'the amendment was refused'
sec "$TW_F" Decisions > "$T/d1"
o=$(ids "$T/d1" | tr ' ' '\n' | grep -E '^D-00[567]$' | tr '\n' ' '); [ "$o" = 'D-005 D-006 D-007 ' ] || fail "the ticket does not quote D-005, then D-006, then D-007, once each: $o"
grep -qF 'replaced-by: D-006, D-007' "$T/d1" || fail "the ticket lacks D-005's mark"
o=$(ids "$T/d1" | tr ' ' '\n' | grep -E '^D-00[5678]$' | tr '\n' ' '); [ "$o" = 'D-005 D-006 D-008 D-007 ' ] || fail "the ticket does not quote the chain D-005, D-006, D-008, once each: $o"
exit 0
