#!/bin/sh
# Purpose: selftest case — the final-review rule reads the enriched grammar only (0.26.10.29.3 phase 2 R4). Under the
# real pre-commit hook and the stub courts (fixtures/stub-courts.sh), in a repository with no commit yet: a spec commit
# adding INVENTORY.md beside a bare-items PRD.md (one ```vid-prd block, no ```vid-prd-answers block), with no
# `review: final` line, passes; the same commit with a ```vid-prd-answers block in PRD.md is refused by=final-review,
# so the exemption is the grammar's, never the rule's absence; and a commit that adds no INVENTORY.md is never asked.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/r"; cd "$T/r"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "final-review-bare-prd-exempt: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# a repository with no commit yet, so the commit that installs checks/ beside PRD.md and INVENTORY.md is the spec
# commit (fresh starts it again); VID_ROLE=fix, as init's spec commit
fresh() { rm -rf .git; git init -q; git config core.hooksPath checks/hooks; rm -f PRD.md INVENTORY.md; }
inv() { printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | anon | n/a | x | REQ-001 | owed: spec-only — first stage\n```\n' > INVENTORY.md; }
bare() { printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | works\n```\n' > PRD.md; }
enriched() { bare; printf '\n```vid-prd-answers\nA-001 | human | 2026-08-27 | Q: who signs in? | A: anyone | settles: REQ-001\n```\n' >> PRD.md; }

fresh; bare; inv; g add -A
VID_ROLE=fix g commit -qm 'bare spec' > "$T/out" 2>&1 || fail 'a bare-items PRD with INVENTORY.md added was refused'
fresh; enriched; inv; g add -A
if VID_ROLE=fix g commit -qm 'enriched spec' > "$T/out" 2>&1; then fail 'an enriched PRD with INVENTORY.md added and no review: final line was accepted'; fi
tail -n 1 .vid/hook-times | grep -q ' by=final-review' || fail 'the enriched refusal is not the final-review block'"'"'s'
fresh; enriched; g add -A
VID_ROLE=fix g commit -qm 'enriched PRD alone' > "$T/out" 2>&1 || fail 'a commit adding no INVENTORY.md was asked for a final review'
exit 0
