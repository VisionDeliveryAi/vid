#!/bin/sh
# Purpose: selftest case — the decisions a written brief carries
# (v0.9.7.0.5 spec 3.2, R4; §6 W-2). The brief-write fixture, with six
# decisions appended. Convicts unless `sh checks/brief.sh write`: joins a
# decision citing a briefed row id, one citing a REQ id of the rows'
# derived-from, and one citing a row only in its why:; never joins on a
# longer id (ROW-102 is not ROW-1020, REQ-002 is not REQ-0021); adds a
# decision that cites nothing only when --decisions names it; refuses an
# unknown --decisions id, writing nothing; gives a grader each decision's
# rule part, the line up to ' | why:', and a fixer the whole lines; and the
# check says ok on both. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-write-decisions: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"
cat >> DECISIONS.md <<'DEC'
- **D-101** ROW-102's refusal names the scheme it refused | why: one message per refusal | enforced: convention
- **D-102** expiry (REQ-003) is checked at resolve time, never by a sweeper | why: no background process | enforced: convention
- **D-103** a code is never reused after deletion | why: settled after the ROW-101 counterexample, slice 2 grader-3 | enforced: convention
- **D-104** ROW-1020's preview shows the target in full | why: a toy | enforced: convention
- **D-105** REQ-0021's limit counts characters | why: a toy | enforced: convention
- **D-106** links are stored in UTC | why: one clock | enforced: convention
DEC
g commit -qam decisions
mkdir -p .vid/ledger-results; S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
rule() { l=$(dline "$1"); printf '%s\n' "${l%% | why:*}"; }
sec3() { sed -n '/^## 3/,/^## 4/p' "$1"; }
# the grader: the join by row id, by REQ id and by an id only in why:, rule parts only
bw_write --role grader --slice 7 --rows ROW-101,ROW-102,ROW-103 --receipt "$S.full.xml" || fail 'the writer refused a grader brief'
G=$(bw_out); sec3 "$G" > "$T/g3"
for d in D-101 D-102 D-103; do grep -qxF -- "$(rule $d)" "$T/g3" || fail "the grader brief lacks $d's rule"; done
grep -qF ' | why:' "$T/g3" && fail 'a grader brief carries a why'
grep -qF 'counterexample' "$G" && fail "D-103's why (a prior verdict) travels to the grader"
grep -q 'D-104\|D-105' "$T/g3" && fail 'a longer id joined (ROW-1020 or REQ-0021)'
grep -q 'D-106' "$T/g3" && fail 'a decision citing nothing joined without --decisions'
# --decisions adds one that cites nothing
bw_write --role grader --slice 7 --rows ROW-102 --receipt "$S.full.xml" --decisions D-106 || fail 'the writer refused --decisions D-106'
sec3 "$(bw_out)" | grep -qxF -- "$(rule D-106)" || fail '--decisions D-106 did not add its rule'
# an unknown id is refused, writing nothing
ls .vid/briefs/7 > "$T/before"
if bw_write --role grader --slice 7 --rows ROW-102 --receipt "$S.full.xml" --decisions D-999; then fail 'an unknown decision id was accepted'; fi
grep -qF 'unknown decision id: D-999' "$T/wout" || fail 'the refusal does not name D-999'
ls .vid/briefs/7 | cmp -s - "$T/before" || fail 'a refused brief left a file'
if bw_write --role fixer --slice 7 --rows ROW-102,ROW-999; then fail 'an unknown row id was accepted'; fi
grep -qF 'unknown row id: ROW-999' "$T/wout" || fail 'the refusal does not name ROW-999'
# the fixer: whole lines
bw_write --role fixer --slice 7 --rows ROW-101,ROW-102,ROW-103 --decisions D-106 || fail 'the writer refused a fixer brief'
F=$(bw_out); sec3 "$F" > "$T/f3"
for d in D-101 D-102 D-103 D-106; do grep -qxF -- "$(dline $d)" "$T/f3" || fail "the fixer brief lacks $d whole"; done
grep -q 'D-104\|D-105' "$T/f3" && fail 'a longer id joined in the fixer brief'
grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok on the fixer brief'
exit 0
