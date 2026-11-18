#!/bin/sh
# Purpose: selftest case — a `review:` line carrying a round counts its block (0.26.10.29.3, phase 2 R2). On the
# known-good PRD fixture, the court (checks/prd.sh, join 13) refuses `review: delta, round 2, 2 findings` over an
# append section whose findings block holds 1 row, naming the count, and a `## Findings` heading whose
# `review: whole, round 3, 1 findings` line stands over 2 rows (two blocks under one heading count together); the same
# section and heading with their counts right pass. In a scratch repository with the real hooks, a new append section
# with `review: delta, round 2, 1 findings` and its one row commits; a repair append with
# `review: whole, round 1, 0 findings, see <heading>` and no findings block commits (block 6c reads this phase's forms);
# the same append saying 2 findings over 1 row is refused. A fence opened by four backticks is closed only by a line
# of at least four: a review: line inside it is not read, and a count mismatch after it is still refused. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "review-line-count-mismatch-refused: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
# infind <file>: the PRD with <file>'s text put under ## Findings, just before ## Ratifications
infind() { awk -v f="$1" '/^## Ratifications$/ { while ((getline l < f) > 0) print l; print "" } { print }' "$F"; }
court() { sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; }
ROW='```vid-prd
REQ-070 | functional | T2 | P2 | A subscriber can pause all digests for a holiday. | fail-if: a digest arrives while the subscriber paused them | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis
```'
ONE='```vid-prd-findings
F-10 | review | advisory | REQ-070 | noted | evidence: the pause has no end date; a subscriber who forgets it gets no digest
```'
{ cat "$F"; printf '\n### 2026-11-15 (/vid add)\n\n%s\n\nreview: delta, round 2, 2 findings\n\n%s\n' "$ROW" "$ONE"; } > PRD.md
if court; then fail 'an append whose review: line counts 2 findings over a block of 1 row passed the court'; fi
grep -q 'join 13.*review: delta, round 2, 2 findings.*1' out.txt || { cat out.txt >&2; fail 'the refusal does not name the line and the rows counted'; }
{ cat "$F"; printf '\n### 2026-11-15 (/vid add)\n\n%s\n\nreview: delta, round 2, 1 findings\n\n%s\n' "$ROW" "$ONE"; } > PRD.md
court || { cat out.txt >&2; fail 'the same append with its count right was refused'; }
cat > h.txt <<'H'
### 2026-11-15 — consolidation review

review: whole, round 3, 1 findings

```vid-prd-findings
F-11 | review | blocking | REQ-001 | repaired | evidence: round 1 — the digest join loses the last-sent time on a re-poll
```

```vid-prd-findings
# round 2
F-12 | review | advisory | REQ-005 | noted | evidence: round 2 — the repair's wording repeats REQ-001's arm
```
H
infind h.txt > PRD.md
if court; then fail 'a Findings heading whose review: line says 1 finding over 2 rows in two blocks passed the court'; fi
grep -q 'join 13' out.txt || { cat out.txt >&2; fail 'the heading refusal is not join 13'; }
sed 's/^review: whole, round 3, 1 findings$/review: whole, round 3, 2 findings/' h.txt > h2.txt; infind h2.txt > PRD.md
court || { cat out.txt >&2; fail 'the heading with its count right (2 rows across two blocks) was refused'; }

# a fence opened by four backticks closes only on a line of at least four: a review: line inside it is not read, and
# a review: line after it is
cat > q.txt <<'H'
### 2026-11-15 — pause 3 sitting

An example, quoted:

````
review: sweep, round 1, 5 findings
```
````

### 2026-11-15 — consolidation review

review: whole, round 1, 2 findings

```vid-prd-findings
F-11 | review | blocking | REQ-001 | repaired | evidence: the digest join loses the last-sent time on a re-poll
```
H
infind q.txt > PRD.md
if court; then fail 'a count mismatch after a closed four-backtick fence passed the court'; fi
grep -q "join 13.*review: whole, round 1, 2 findings" out.txt || { cat out.txt >&2; fail 'the mismatch after the four-backtick fence is not named'; }
grep -q 'sweep' out.txt && { cat out.txt >&2; fail 'a review: line inside a four-backtick fence was read'; }
sed 's/^review: whole, round 1, 2 findings$/review: whole, round 1, 1 findings/' q.txt > q2.txt; infind q2.txt > PRD.md
court || { cat out.txt >&2; fail 'the same PRD with its count right was refused (the fenced line was read?)'; }

# the hook: block 6c takes this phase's forms
mkdir -p r && cd r
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh lawfiles event.sh eol.sh; do [ -f "$CHECKS/$c" ] && cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
infind ../h2.txt > PRD.md
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising' >/dev/null
git config core.hooksPath checks/hooks
door() { # <body>: a dated append section committed through the hooks → ACCEPTED | REFUSED
  cp PRD.md PRD.base
  printf '\n### %s (/vid add)\n\n%s\n' "$1" "$2" >> PRD.md
  g add PRD.md
  if g commit -qm "an append

Decisions: none — a review probe" > out.txt 2>&1; then echo ACCEPTED; else cp PRD.base PRD.md; g reset -q; echo REFUSED; fi; }
[ "$(door 2026-11-16 "$ROW

review: delta, round 2, 2 findings

$ONE")" = REFUSED ] || fail 'the hook accepted a new append whose round line counts 2 findings over 1 row'
[ "$(door 2026-11-16 "$ROW

review: delta, round 2, 1 findings

$ONE")" = ACCEPTED ] || { cat out.txt >&2; fail 'the hook refused a new append with review: delta, round 2, 1 findings and its one row'; }
[ "$(door 2026-11-17 "$(printf '%s\n' "$ROW" | sed 's/REQ-070 |/REQ-070 AMENDED |/; s/for a holiday/for a holiday of up to a month/; s/authority: authoritative/authority: authoritative | arms: 1 retained/')

review: whole, round 1, 0 findings, see 2026-11-15 — consolidation review")" = ACCEPTED ] || { cat out.txt >&2; fail 'the hook refused a repair append carrying review: whole, round 1, 0 findings, see <heading>'; }
echo 'review-line-count-mismatch-refused: ok'
