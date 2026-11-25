#!/bin/sh
# Purpose: selftest case — a Fail-if amendment is counted when its commit passes, once (FB-4 C2). Real hooks: an append
# holding a REQ-012 AMENDED row with no review: line is refused and counts nothing; the same append with its line lands
# and writes one `failif-amendment n=1`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
git config user.email vid@selftest; git config user.name vid
fail() { echo "failif-counted-once: $*" >&2; cat out.txt .vid/metrics-events >&2 2>/dev/null; exit 1; }
mkdir -p checks/hooks .vid
for c in placement.sh conformance.sh prd.sh lawfiles event.sh; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
cp "$CHECKS/selftest/fixtures/prd-094-good.md" PRD.md
printf '.vid/\nout.txt\n' > .gitignore
git add -A && git commit -qm root --no-verify
git config core.hooksPath checks/hooks
MSG='an append

Decisions: none — a probe'
R=$(grep '^REQ-012 ' PRD.md | sed 's/^REQ-012 /REQ-012 AMENDED /; s/$/ | arms: 1 retained, 2 retained/')
printf '\n### 2026-09-02 (/vid fix correction)\n\n```vid-prd\n%s\n```\n' "$R" >> PRD.md; git add PRD.md
if git commit -qm "$MSG" > out.txt 2>&1; then fail 'an append with no review: line was committed'; fi
grep -q 'no review: line' out.txt || fail 'refused for another reason'
[ "$(grep -c '^failif-amendment ' .vid/metrics-events || true)" = 0 ] || fail 'a refused commit counted its amendment'
printf '\nreview: delta, round 1, 0 findings\n' >> PRD.md; git add PRD.md
git commit -qm "$MSG" > out.txt 2>&1 || fail 'the append with its review: line was refused'
[ "$(grep -c '^failif-amendment n=1 ' .vid/metrics-events || true)" = 1 ] || fail 'the landed amendment is not counted once'
exit 0
