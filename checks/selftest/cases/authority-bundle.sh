#!/bin/sh
# Purpose: selftest case — the authority bundle in briefs (v0.9.8 spec 3.3, R5). Convicts unless a test-author brief
# and a grader brief for ROW-201 each carry `## 15 authority`: the answer its item's source: cites, quoted as its
# latest row (A-001 AMENDED), and the design state its marker cites with the file holding it; unless the check refuses
# a section 15 whose answer line is not PRD.md's verbatim, or whose design line names a marker the row does not
# carry; and unless `brief.sh authority --row ROW-201` prints the row's arm, answer, decisions, design state and a
# digest. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "authority-bundle: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
au_repo "$T/repo"
AMEND='A-001 AMENDED | human | 2026-10-05 | Q: how long does a link last? | A: seven days, counted from creation | settles: REQ-001'
w() { CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write "$@" > "$T/out" 2>&1 || fail "the brief was refused: $*"; sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1; }
TA=$(w --role test-author --slice 1 --rows ROW-201)
mkdir -p .vid/ledger-results; printf '<report/>\n' > .vid/ledger-results/r.xml
GR=$(w --role grader --slice 1 --rows ROW-201 --receipt r.xml)
for b in "$TA" "$GR"; do
  grep -qx '## 15 authority' "$b" || fail "$b carries no section 15"
  awk '/^## [0-9]/ { on = ($2 == 15); next } on' "$b" > "$T/s15"
  grep -qxF -- "$AMEND" "$T/s15" || fail "$b does not quote the answer's latest row"
  grep -qF 'A-001 | human | 2026-10-01' "$T/s15" && fail "$b quotes the answer's superseded row"
  grep -q '^A-002' "$T/s15" && fail "$b quotes an answer no briefed item cites"
  grep -qx 'ROW-201 P01/empty design/screens/p01.html' "$T/s15" || fail "$b does not name the design state and its file"
done
# the check: a paraphrased answer, a marker the row does not carry
unstamp() { grep -v '^written: ' "$TA" | sed "$1" > "$T/b.md"; }
unstamp 's/A: seven days, counted from creation/A: a week/'
if sh checks/brief.sh "$T/b.md" > "$T/out" 2>&1; then fail 'a paraphrased answer passed the check'; fi
grep -q 'section 15: answer A-001' "$T/out" || fail 'the refusal does not name the answer'
unstamp 's#^ROW-201 P01/empty #ROW-201 P02/full #'
if sh checks/brief.sh "$T/b.md" > "$T/out" 2>&1; then fail 'a design line with a foreign marker passed the check'; fi
grep -q 'section 15: P02/full is not a marker of ROW-201' "$T/out" || fail 'the refusal does not name the marker'
# the bundle, one row
sh checks/brief.sh authority --row ROW-201 > "$T/out" 2>&1 || fail 'authority --row refused'
grep -qx 'arm REQ-001 A link lasts seven days. || fail-if: a link works after seven days' "$T/out" || fail 'the arm is not its statement and fail-if'
grep -qx 'answer A-001 A: seven days, counted from creation' "$T/out" || fail 'the answer is not its latest A: text'
[ "$(grep -c '^decision ' "$T/out")" -eq 3 ] || fail 'the bundle does not hold three decisions'
grep -qx 'design P01/empty design/screens/p01.html' "$T/out" || fail 'the design state is missing'
grep -qE '^digest [0-9]+$' "$T/out" || fail 'no digest'
exit 0
