# Purpose: selftest fixture — a toy spec-only ViD tree, as a 0.26.10.9 init leaves it (spec R1, R3; §5 init-spec-only,
# vid-repo-copies, append-tickets, skeleton-order). Sourced (Env: CHECKS). so_tree <dir>: a repository with no commit
# holding PRD.md (fixtures/prd-known-good.md with a final findings heading), CLAUDE.md placing app/, BASELINE.md, ARCHITECTURE.md (a module table, no seam),
# DECISIONS.md, GRADING-CHECKLIST.md and INVENTORY.md (grammar 0.9.3: ROW-001..ROW-004 `owed: spec-only — first stage`,
# ROW-005 owed to deploy gate 2, RULE-001 census-armed, HOS-001 guard-first), and the plugin's whole checks/ copied as
# init copies it — its shipped self-test cases replaced by one toy case, so a law commit's suite run is quick — with the hooks path
# set. No code, no harness, no extractor. so_commit <message summary>: commits through the real hooks under
# VID_ROLE=fix with the template message. so_row <id> <test field>: rewrites a ROW row's test field.
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
so_tree() {
  mkdir -p "$1"; cd "$1"; git init -q
  mkdir -p checks; cp -R "$CHECKS/." checks/; rm -f checks/selftest/cases/*.sh
  printf '#!/bin/sh\n# Purpose: the toy'"'"'s one self-test case\nexit 0\n' > checks/selftest/cases/toy-case.sh
  git config core.hooksPath checks/hooks
  # 0.26.10.29.3 (phase 2 R4): the spec commit adds INVENTORY.md beside an enriched PRD, so the PRD carries init's final
  # review: a dated findings heading with its `review: final` line and no rows, before the Ratifications section
  awk '/^## Ratifications/ { print "### 2026-08-30 — final review"; print ""; print "review: final, round 1, 0 findings, read: PRD.md ARCHITECTURE.md DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md"; print "" } { print }' \
    "$CHECKS/selftest/fixtures/prd-known-good.md" > PRD.md
  printf '# toy\n\n```vid-placement\napp/\n```\n' > CLAUDE.md
  printf '# toy\n\n```vid-allowed-extensions\n.py .sh .md .yml .txt .html .css .xml .json\n```\n\n```vid-forbidden\nzq''xk\n```\n' > BASELINE.md
  printf '# Architecture\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| app/notes | notes | notes | `app.notes.api` | none |\n\nImport court: off\n' > ARCHITECTURE.md
  printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md
  printf '# Grading checklist\n\n- the notes page reads well\n' > GRADING-CHECKLIST.md
  cat > INVENTORY.md <<'INV'
# Inventory

```vid-inventory
grammar: 0.9.3
ROW-001 | behavior | REQ-001 | anonymous | n/a | a wrong password is refused | REQ-001 | owed: spec-only — first stage
ROW-002 | behavior | REQ-002 | anonymous | n/a | a saved note survives | REQ-002 | owed: spec-only — first stage
ROW-003 | behavior | REQ-003 | anonymous | n/a | a note shows its own text | REQ-003 | owed: spec-only — first stage
ROW-004 | behavior | REQ-002 | anonymous | n/a | an empty note is refused | REQ-002 | owed: spec-only — first stage
ROW-005 | behavior | REQ-001 | anonymous | n/a | the sign-in page is served over TLS | REQ-001 | owed: paid by /vid deploy gate 2
rule | RULE-001 | every note write is logged | echo app/ | 1 | owed: census-armed — no site yet
hostility | HOS-001 | sign in with a wrong password | protects: REQ-001 | disable: drop the password check | owed: guard-first — HOS-001's guard; paid in the slice that builds sign-in
```
INV
  printf '.vid/\n' > .gitignore
}
so_msg() { printf '%s\n\nREQs: none\nDecisions: none — nothing surprising\nSeams: none\n%s' "$1" "${2:-}"; }
so_commit() { g add -A && VID_ROLE=fix g commit -q -m "$(so_msg "$1" "${2:-}")"; }
so_row() { awk -v id="$1" -v t="$2" 'BEGIN { FS = " [|] "; OFS = " | " } $1 == id { $8 = t } { print }' INVENTORY.md > INVENTORY.md.t && mv INVENTORY.md.t INVENTORY.md; }
