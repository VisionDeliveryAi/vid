#!/bin/sh
# Purpose: selftest case — a phase-1 `review:` line's count is never judged once committed (0.26.10.29.3, phase 2
# R2). A PRD whose append section carries `review: delta, 3 findings` over a findings block of 1 row passes the court
# (checks/prd.sh) outside any repository, as a ratified PRD adopted into a new project is read; in a scratch
# repository with the real hooks, where that section is committed, a later append with its own review line commits.
# The court does read that section: the same line in this phase's form (`round 1`) is refused. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "review-line-committed-count-not-judged: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/adopt" "$T/r"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
OLD='
### 2026-10-01 (/vid add)

```vid-prd
REQ-070 | functional | T2 | P2 | A subscriber can pause all digests for a holiday. | fail-if: a digest arrives while the subscriber paused them | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis
```

review: delta, 3 findings

```vid-prd-findings
F-10 | review | advisory | REQ-070 | noted | evidence: the pause has no end date
```'
cd "$T/adopt"
{ cat "$F"; printf '%s\n' "$OLD"; } > PRD.md
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'a phase-1 line whose count differs was refused outside a repository'; }
{ cat "$F"; printf '%s\n' "$OLD" | sed 's/^review: delta, 3 findings$/review: delta, round 1, 3 findings/'; } > PRD.md
if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail 'the same count in a round line passed — the court does not read the section'; fi
cd "$T/r"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh lawfiles event.sh eol.sh; do [ -f "$CHECKS/$c" ] && cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
{ cat "$F"; printf '%s\n' "$OLD"; } > PRD.md
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising' >/dev/null
git config core.hooksPath checks/hooks
printf '\n### 2026-10-02 (/vid add)\n\n```vid-prd\nREQ-071 | functional | T2 | P2 | A subscriber can pause digests for a fortnight. | fail-if: a digest arrives in the paused fortnight | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis\n```\n\nreview: delta, round 1, 0 findings\n' >> PRD.md
g add PRD.md
g commit -qm 'an append

Decisions: none — a review probe' > out.txt 2>&1 || { cat out.txt >&2; fail 'a later append was refused over a committed phase-1 line whose count differs'; }
echo 'review-line-committed-count-not-judged: ok'
