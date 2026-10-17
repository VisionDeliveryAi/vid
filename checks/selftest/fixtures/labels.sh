# Purpose: selftest fixture — the labelling pass's toy project (v0.9.7.3 spec 3.3, R3). Sourced by a case after it has
# made and entered $T (Env: CHECKS, T): the stub courts and the real hooks (fixtures/stub-courts.sh; commit-msg), with
# checks/decisions.sh and event.sh beside them (a case that reads the protected rows copies inventory.sh over the stub). lb_files writes INVENTORY.md (ROW-001 marks LOGIN/form
# from REQ-001, ROW-002 derives from the Tier-0 REQ-002 and carries divergence: DIF-001, ROW-003 from REQ-001; the
# tier-0 RULE-001 and tier-1 RULE-002, origin: REQ-001 and REQ-009), PRD.md and DECISIONS.md: D-001 cites ROW-001;
# D-002 and D-003 cite no id; D-004 is labelled scope: project; D-005's enforced: names a ledger test that does not
# exist; D-006 is followed by origin:. lb_hooks points core.hooksPath at checks/hooks. lb_hash <D-id>: the hash
# `propose` gives the line. lb_prop <lines…>: .vid/decision-labels.proposed.
. "$CHECKS/selftest/fixtures/stub-courts.sh"
mkdir -p .vid
cp "$CHECKS/decisions.sh" "$CHECKS/event.sh" checks/
cp "$CHECKS/hooks/commit-msg" checks/hooks/   # the labels commit passes the project's commit-msg hook too
lb_files() {
  printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\nROW-002 | behavior | leak | anon | n/a | x | REQ-002 | owed: prerequisite — later | divergence: DIF-001\nROW-003 | behavior | audit | anon | n/a | x | REQ-001 | owed: prerequisite — later\nrule | RULE-001 | sessions expire | grep x | 0 | owed: census-armed — later | origin: REQ-001\nrule | RULE-002 | audits ordered | grep y | 1 | owed: census-armed — later | origin: REQ-009\n```\n' > INVENTORY.md
  printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | works\nREQ-002 | functional | T0 | never leaks\nREQ-009 | functional | T1 | ordered\n```\n' > PRD.md
  printf '# DECISIONS\n\n## Log\n\n- **D-001** ROW-001 shows one form | why: x | enforced: convention\n- **D-002** sessions last a day | why: load | enforced: convention\n- **D-003** one font everywhere | why: brand | enforced: convention\n- **D-004** logs kept a year | why: audit | enforced: convention | scope: project\n- **D-005** tokens are eight characters | why: enough | enforced: tests/invariants/test_gone.py\n- **D-006** prices in minor units | why: exactness | enforced: convention | origin: proposal\n' > DECISIONS.md
}
lb_hooks() { git config core.hooksPath checks/hooks; }
lb_hash() { grep -F -- "- **$1**" DECISIONS.md | head -n 1 | git hash-object --stdin | cut -c1-12; }
lb_prop() { : > .vid/decision-labels.proposed; for _l in "$@"; do printf '%s\n' "$_l" >> .vid/decision-labels.proposed; done; }
