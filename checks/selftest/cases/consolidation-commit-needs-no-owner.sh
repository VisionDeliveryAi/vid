#!/bin/sh
# Purpose: selftest case — consolidation adds no ruling (0.26.10.29.3, R2).
# HEAD holds the known-good PRD (its human answers, an amended answer in an
# append); checks/prd-consolidate.sh drops every Q: text and folds the
# AMENDED answer into the base. The commit-msg hook passes the staged
# consolidation with no Owner: trailer: no answer's id, tier or A: is new.
# The exemption is read from the answers, not from the commit's kind: the
# same consolidation staged with one new human answer is refused without the
# trailer. Env: CHECKS.
set -eu
FIXTURES="$CHECKS/selftest/fixtures"; HOOK="$CHECKS/hooks/commit-msg"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "consolidation-commit-needs-no-owner: $*" >&2; exit 1; }
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
cp "$FIXTURES/prd-known-good.md" PRD.md
g add PRD.md && g commit -qm 'root' --no-verify
sh "$CHECKS/prd-consolidate.sh" PRD.md --date 2026-09-30 >c.txt 2>&1 || { cat c.txt >&2; fail 'the consolidation refused the fixture'; }
grep -q '| Q:' PRD.md && fail 'the consolidation kept Q: text'
grep -q '^A-005 | human |' PRD.md || fail 'the amended answer did not move into the base'
g add -A
printf 'Consolidation (7a)\n\nDecisions: none — the mechanical copy\n' > msg
sh "$HOOK" msg >out 2>&1 || { cat out >&2; fail 'the consolidation commit was refused with no Owner: trailer'; }
printf '\n### 2026-09-30 (owner answer)\n\n```vid-prd-answers\nA-007 | human | 2026-09-30 | Q: may a subscriber pause digests? | A: yes, for up to four weeks | settles: REQ-001\n```\n' >> PRD.md
g add PRD.md
if sh "$HOOK" msg >out 2>&1; then fail 'a consolidation carrying a new human answer was accepted with no Owner: trailer'; fi
grep -q 'A-007' out || { cat out >&2; fail 'the refusal does not name A-007'; }
exit 0
