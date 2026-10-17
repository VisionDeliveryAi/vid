# Purpose: selftest fixture — a toy project with one held row, for the hold-flag cases (v0.9.8.1 R30). Sourced in a
# scratch directory (Env: CHECKS). hf_repo makes a repository under `grammar: 0.9.3` (the known-good PRD, rows ROW-001
# and ROW-002, a passing receipt) whose events hold ROW-001 `reason=rounds` (BREACHED, reissued, BREACHED), with
# metrics.sh and the observer beside it. hf_ev <line>: an event appended. flags: the `hold FLAG` lines of closure.
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
hf_repo() {
  git init -q; mkdir -p checks/extractors tests/invariants app .vid/ledger-results
  for c in metrics.sh lawfiles observe.sh watchdog.sh census.sh brief.sh prd.sh; do cp "$CHECKS/$c" checks/ 2>/dev/null || true; done
  printf '#!/bin/sh\n# Purpose: results reader (fixture)\n[ -f "${1:-}" ] || { echo "inactive no report"; exit 0; }\nsed -n '"'"'s/.*<case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
  cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
  printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py; printf '# Purpose: toy\n' > app/main.py
  printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one digest a day | REQ-001 | tests/invariants/t.py\nROW-002 | behavior | REQ-002 | n/a | n/a | the unsubscribe link stops every digest | REQ-002 | tests/invariants/t.py\n```\n' > INVENTORY.md
  printf '.vid/\n' > .gitignore; g add -A && g commit -qm root
  S=$(git rev-parse --short=12 HEAD)
  { echo '<r>'; for r in 001 002; do printf '<case name="tests/invariants/t.py::t[ROW-%s]" status="passed" time="0.1"/>\n' "$r"; done; echo '</r>'; } > ".vid/ledger-results/$S.full.xml"
  { printf 'verdict slice=1 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/1.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$S"
    printf 'reissued row=ROW-001 why=A-1 rounds=1 at=2026-10-02T09:01:00Z\n'
    printf 'verdict slice=2 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/2.md quoted-at=%s at=2026-10-02T09:02:00Z\n' "$S"; } > .vid/metrics-events
}
hf_ev() { printf '%s\n' "$1" >> .vid/metrics-events; }
flags() { sh checks/metrics.sh closure 2>/dev/null | grep '^hold FLAG ' || true; }
