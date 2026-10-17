# Purpose: selftest fixture — the red line (v0.9.7.0.7 spec 3.4; §6 D-1…D-3). Sourced after the case
# has made and entered $T (Env: CHECKS, T). rl_dir makes a directory with an INVENTORY.md whose
# ROW-101 cites tests/invariants/links.sh and ROW-1010 tests/invariants/other.sh; rl_case <name>
# <attrs> <body> appends one failed JUnit testcase to $T/r.xml (classname tests.invariants.links);
# rl_red prints `sh checks/evidence.sh red r.xml` into $T/out.
rl_dir() {
  mkdir -p "$T/p/.vid/ledger-results"; cd "$T/p"
  printf '# toy\n\n```vid-inventory\ngrammar: 0.9.3\nROW-101 | behavior | REQ-001 | anonymous | n/a | a code resolves | REQ-001 | tests/invariants/links.sh\nROW-1010 | behavior | REQ-002 | anonymous | n/a | another | REQ-002 | tests/invariants/other.sh\n```\n' > INVENTORY.md
  printf '<?xml version="1.0"?>\n<testsuites><testsuite name="t">\n' > "$T/r.xml"
}
rl_case() { printf '<testcase classname="tests.invariants.links" name="%s"%s><failure message="AssertionError: wrong">%s</failure></testcase>\n' "$1" "$2" "$3" >> "$T/r.xml"; }
rl_red() { printf '</testsuite></testsuites>\n' >> "$T/r.xml"; cp "$T/r.xml" .vid/ledger-results/r.xml; sh "$CHECKS/evidence.sh" red r.xml > "$T/out" 2>&1; }
