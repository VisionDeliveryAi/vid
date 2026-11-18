#!/bin/sh
# Purpose: selftest case — appends already committed are never judged for
# their review (0.26.10.29.3, R3). Real commits in a scratch repository with
# the real hooks installed: HEAD's PRD (the known-good fixture) holds two
# appends with no `review:` line; a commit that changes the PRD and adds no
# section is accepted, whatever those appends carry, and so is the first
# commit of a PRD.md HEAD does not hold. A new section is told
# from an old one by count, not by its heading: a section repeating an old
# heading, holding a row and no line, is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "append-in-head-not-judged: $*" >&2; exit 1; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh lawfiles event.sh; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
printf '.vid/\n' > .gitignore
[ "$(sed -n '/^## Appends$/,$p' PRD.md | grep -c '^### ')" -eq 2 ] && ! grep -q '^review:' PRD.md || fail 'the fixture no longer holds two appends without a review: line'
g add -A && g commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
# the first commit of a PRD.md HEAD does not hold (an adopted file): its appends were committed where it was written
git rm -q --cached PRD.md && g commit -qm 'the PRD set aside

Decisions: none — nothing surprising' >out.txt 2>&1 || { cat out.txt >&2; fail 'setting the PRD aside was refused'; }
g add PRD.md
g commit -qm 'adopt PRD.md

Decisions: none — nothing surprising' >out.txt 2>&1 || { cat out.txt >&2; fail 'the first commit of a PRD.md, appends and all, was judged for their review'; }
awk '{ print } /^No source conflicts: the seed is the only source in this run\.$/ { print "The trade forums the journeys name are the only outside channel." }' PRD.md > p && mv p PRD.md
git diff --quiet PRD.md && fail 'the prose edit did not change PRD.md'
g add PRD.md
g commit -qm 'a prose line

Decisions: none — nothing surprising' >out.txt 2>&1 || { cat out.txt >&2; fail 'a commit adding no append section was refused over the appends HEAD holds'; }
printf '\n### 2026-08-28 (owner answer)\n\n```vid-prd\nREQ-070 | functional | T2 | P2 | A subscriber can pause all digests for a holiday. | fail-if: a digest arrives while the subscriber paused them | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis\n```\n' >> PRD.md
g add PRD.md
if g commit -qm 'a section under an old heading

Decisions: none — a review probe' >out.txt 2>&1; then fail 'a new section repeating an old heading was taken for an old one and accepted with no review: line'; fi
grep -q 'review: delta' out.txt || { cat out.txt >&2; fail 'the refusal is not the review rule'; }
exit 0
