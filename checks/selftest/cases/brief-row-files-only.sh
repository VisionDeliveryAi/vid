#!/bin/sh
# Purpose: selftest case — writer and grader briefs name only the rows' own files (v0.9.8.1 R19). The brief-write
# fixture with a per-screen design pack (P01, P03, the component groups C00-forms and C00-nav, an index giving P03
# C00-forms only), another row's test file and the measure module. Convicts unless a test-author brief for ROW-120
# (P03/form) lists its own test file and the measure module and no other test file, its design line names P03's own
# canvas, and its components line, apart, names C00-forms only; a grader brief for ROW-101 lists its own test file
# and the measure module; both pass the check; and with the index gone (a legacy pack) the components line names
# every file holding a C00 marker. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; B=""
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-row-files-only: $*" >&2; cat "$T/wout" >&2 2>/dev/null; cat "$B" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
cp "$CHECKS/design-join.sh" checks/
printf '# Purpose: another row'"'"'s ledger (toy)\n' > tests/invariants/other.sh
printf '# Purpose: the measure module (toy)\n' > tests/invariants/measure.sh
mkdir -p design/screens
printf '<!-- @screen P01 state=empty reqs=REQ-001 -->\n<div>none</div>\n' > "design/screens/P01 Home.dc.html"
printf '<!-- @screen P03 state=form reqs=REQ-004 -->\n<form></form>\n' > "design/screens/P03 Form.dc.html"
printf '<!-- @screen C00 state=field reqs=REQ-004 -->\n<input>\n' > design/screens/C00-forms.dc.html
printf '<!-- @screen C00 state=nav reqs=REQ-001 -->\n<nav></nav>\n' > design/screens/C00-nav.dc.html
printf '{"layout": "per-screen", "files": ["P01 Home.dc.html", "P03 Form.dc.html", "C00-forms.dc.html", "C00-nav.dc.html"], "components": {"P03": ["C00-forms.dc.html"]}}\n' > design/screens/index.json
g add -A && g commit -qm 'a per-screen pack'
bw_write --role test-author --slice 2 --rows ROW-120 || fail 'the test-author brief was refused'; B=$(bw_out)
s8() { awk '/^## 8 /{ on = 1; next } /^## /{ on = 0 } on' "$B"; }
s8 | grep -qx 'tests/invariants/surfaces.sh' && s8 | grep -qx 'tests/invariants/measure.sh' || fail "the test-author brief lacks the row's own test file or the measure module"
s8 | grep -qx 'tests/invariants/links.sh\|tests/invariants/other.sh' && fail 'the test-author brief lists a test file of another row'
grep -qx 'ROW-120 P03/form design/screens/P03 Form.dc.html' "$B" || fail "the design line does not name P03's own canvas"
grep -qx 'components P03 design/screens/C00-forms.dc.html' "$B" || fail 'the components line is not the index'"'"'s for P03'
sh checks/brief.sh "$B" > "$T/wout" 2>&1 || fail 'the test-author brief fails the check'
mkdir -p .vid/ledger-results; printf "<report/>\n" > .vid/ledger-results/a.xml
bw_write --role grader --slice 2 --rows ROW-101 --receipt a.xml || fail 'the grader brief was refused'; B=$(bw_out)
s8 | grep -qx 'tests/invariants/links.sh' && s8 | grep -qx 'tests/invariants/measure.sh' || fail "the grader brief lacks the row's own test file or the measure module"
s8 | grep -qx 'tests/invariants/other.sh' && fail 'the grader brief lists a test file of another row'
sh checks/brief.sh "$B" > "$T/wout" 2>&1 || fail 'the grader brief fails the check'
g rm -q design/screens/index.json; g commit -qm 'a legacy pack'
bw_write --role test-author --slice 2 --rows ROW-120 || fail 'the legacy test-author brief was refused'; B=$(bw_out)
grep -qx 'components P03 design/screens/C00-forms.dc.html,design/screens/C00-nav.dc.html' "$B" || fail 'a legacy pack does not give the whole components canvas'
exit 0
