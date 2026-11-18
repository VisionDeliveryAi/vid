#!/bin/sh
# Purpose: selftest case — the spec commit carries its final review (0.26.10.29.3 phase 2 R4). On the toy spec-only
# tree (fixtures/spec-only.sh, whose PRD.md is in the enriched grammar and carries a final findings heading with its
# `review: final` line), under the real hooks: the commit that adds INVENTORY.md is refused by=final-review when the
# staged PRD.md holds no `review: final` line, and passes with it; a `review: final` line HEAD's PRD.md already holds
# is not a new one, so the spec commit after the PRD's own commit is refused until a second final heading is added;
# and an INVENTORY.md renamed from a draft the same commit removes counts as added, whatever diff.renames says. The
# refusal is the hook's own block, named in the refusal; the PRD court judges the line's form. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "final-review-with-inventory: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
nofinal() { awk '/^review: final/ { next } { print }' PRD.md > "$T/p" && cp "$T/p" PRD.md; }
heading() { awk -v d="$1" '/^## Ratifications/ { print "### " d " — final review"; print ""; print "review: final, round 1, 0 findings, read: PRD.md ARCHITECTURE.md DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md"; print "" } { print }' PRD.md > "$T/p" && cp "$T/p" PRD.md; }
refused_here() { tail -n 1 .vid/hook-times | grep -q ' by=final-review' && grep -q 'no new `review: final` line' "$T/out"; }

# 1. the spec commit without the line is refused, by this block
so_tree "$T/r"
grep -q '^review: final, round 1, 0 findings, read: ' PRD.md || fail 'the spec-only fixture gives its PRD no final findings heading'
cp PRD.md "$T/prd.full"; nofinal
if so_commit 'the spec' > "$T/out" 2>&1; then fail 'a commit adding INVENTORY.md with no review: final line was accepted'; fi
refused_here || fail 'the refusal is not the final-review block'"'"'s'
# 2. the same commit with the line passes the whole hook
cp "$T/prd.full" PRD.md
so_commit 'the spec' > "$T/out" 2>&1 || { refused_here && fail 'the final-review block refused a PRD with its review: final line'; fail 'the spec commit with its review: final line was refused by another court (lane D'"'"'s join 13 judges the line)'; }
[ "$(git log -1 --format=%s)" = 'the spec' ] || fail 'the spec commit did not land'

# 3. a line HEAD's PRD.md already holds is not new: the PRD is committed first, as create-prd's ratifications are,
# before the hooks exist
so_tree "$T/s"
g add PRD.md && g -c core.hooksPath=/dev/null commit -q -m 'the PRD, ratified before the hooks are installed' || fail 'the PRD could not be committed'
if so_commit 'the inventory' > "$T/out" 2>&1; then fail 'a review: final line HEAD already holds was taken for a new one'; fi
refused_here || fail 'the refusal of an old line is not the final-review block'"'"'s'
heading 2026-08-31
so_commit 'the inventory' > "$T/out" 2>&1 || fail 'a second final heading did not pass'

# 4. an INVENTORY.md the commit renames from a draft is still added: with diff.renames on, git would report it R100
so_tree "$T/d"; git config diff.renames true; nofinal
mv INVENTORY.md INVENTORY.draft.md
g add PRD.md INVENTORY.draft.md && g -c core.hooksPath=/dev/null commit -q -m 'the PRD and a draft inventory, before the hooks' || fail 'the draft could not be committed'
g mv INVENTORY.draft.md INVENTORY.md
if so_commit 'the spec' > "$T/out" 2>&1; then fail 'an INVENTORY.md renamed from a draft, beside an enriched PRD with no review: final line, was accepted'; fi
refused_here || fail 'the renamed draft'"'"'s refusal is not the final-review block'"'"'s'
exit 0
