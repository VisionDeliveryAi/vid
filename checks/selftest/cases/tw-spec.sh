#!/bin/sh
# Purpose: selftest case — the spec repository is §3.8's, W2 and F16 (v0.26.10.12.3 R2; from
# cefc763, re-planted on stage 1's toy). On the toy (no design/): spec-export is refused before set-up. spec-setup
# makes owner/code-spec private, with the one `gh repo create owner/code-spec --private`, and exports: design/ is named
# and left out; the export's tree is exactly ARCHITECTURE.md, BASELINE.md, DECISIONS.md, GRADING-CHECKLIST.md, PRD.md
# and TEST-DIFFERENCES.md (INVENTORY.md's three difference lines, verbatim) as at ViD's HEAD — never INVENTORY.md,
# PLAN.md, STAGES.md, CLAUDE.md, a test or .vid/; its author and committer are ViD <vid@export.invalid>, even with the
# owner's address in the environment; ViD's index, refs and working tree are unchanged; the log says `spec-repo
# owner/code-spec created` and `export <commit> from=<HEAD> state=pushed`. Again: nothing pushed, `state=unchanged`; a
# committed change to PLAN.md, or to an INVENTORY.md line that is no difference, pushes nothing; a changed difference
# line, and design/ added, each a fast-forward. A second spec-setup finds the repository (`exists`). A public
# repository, and the code repository, named as spec-repo: are refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-spec: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
GS=$CHECKS/github.sh; SR=$T/gh/repos/owner%code-spec/remote.git
tree() { git -C "$SR" ls-tree -r --name-only "$1" | paste -sd ' ' -; }
if sh "$GS" spec-export > "$T/out" 2>&1; then fail 'spec-export passed before the spec repository exists'; fi
grep -q 'no access to the spec repository owner/code-spec' "$T/out" || fail 'the refusal does not name the missing repository'
IDX0=$(git ls-files -s | git hash-object --stdin); REFS0=$(git for-each-ref | git hash-object --stdin)
GIT_AUTHOR_EMAIL=owner@home.example GIT_COMMITTER_EMAIL=owner@home.example sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
[ "$(cat "$T/gh/repos/owner%code-spec/private")" = true ] || fail 'the spec repository is not private'
[ "$(grep -c '^gh repo create' "$T/gh/log")" = 1 ] && grep -qx 'gh repo create owner/code-spec --private' "$T/gh/log" || fail 'not one gh repo create owner/code-spec --private'
grep -q '^spec-repo owner/code-spec created at=' .vid/tw/log || fail 'the creation is not logged'
grep -q 'design/ is not at HEAD — not exported' "$T/out" || fail 'the missing design/ is not named'
H=$(git rev-parse HEAD); C1=$(git -C "$SR" rev-parse -q --verify refs/heads/main) || fail 'nothing was pushed'
[ "$(tree "$C1")" = 'ARCHITECTURE.md BASELINE.md DECISIONS.md GRADING-CHECKLIST.md PRD.md TEST-DIFFERENCES.md' ] || fail "the export holds $(tree "$C1")"
for f in PRD.md BASELINE.md DECISIONS.md GRADING-CHECKLIST.md ARCHITECTURE.md; do [ "$(git -C "$SR" rev-parse "$C1:$f")" = "$(git rev-parse "HEAD:$f")" ] || fail "the export's $f is not ViD's at HEAD"; done
git -C "$SR" show "$C1:TEST-DIFFERENCES.md" | grep '^difference ' > "$T/d1"; grep '^difference ' INVENTORY.md > "$T/d0"
cmp -s "$T/d0" "$T/d1" && [ "$(grep -c . "$T/d1")" = 3 ] || fail 'TEST-DIFFERENCES.md is not the three difference lines verbatim'
[ "$(git -C "$SR" log -1 --format='%an <%ae> %cn <%ce>' "$C1")" = 'ViD <vid@export.invalid> ViD <vid@export.invalid>' ] || fail "the export is authored as $(git -C "$SR" log -1 --format='%an <%ae>, %cn <%ce>' "$C1")"
grep -q "^export $C1 from=$H state=pushed at=" .vid/tw/log || fail 'the export is not logged'
[ "$(git ls-files -s | git hash-object --stdin)" = "$IDX0" ] && [ "$(git for-each-ref | git hash-object --stdin)" = "$REFS0" ] && [ -z "$(git status --porcelain)" ] || fail "the export changed ViD's index, refs or working tree"
# unchanged: nothing pushed; PLAN.md alone, or a row that is no difference: nothing pushed
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the second export failed'
[ "$(git -C "$SR" rev-parse refs/heads/main)" = "$C1" ] || fail 'an unchanged export pushed'
grep -q "^export $C1 from=$H state=unchanged at=" .vid/tw/log || fail 'the unchanged export is not logged'
printf '\n' >> PLAN.md; g commit -qam 'PLAN.md alone'
sed 's/one digest a day, holding/one digest each day, holding/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; g commit -qam 'ROW-001 alone'
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export after PLAN.md failed'
[ "$(git -C "$SR" rev-parse refs/heads/main)" = "$C1" ] || fail 'a change to PLAN.md or a row that is no difference pushed an export'
# a difference changed, then design/: each a fast-forward
sed 's/a fixed synonym table/a fixed table of synonyms/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; g commit -qam 'DIF-001'
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export after DIF-001 failed'
C2=$(git -C "$SR" rev-parse refs/heads/main); [ "$C2" != "$C1" ] && [ "$(git -C "$SR" rev-parse "$C2^")" = "$C1" ] || fail 'a changed difference is not a fast-forward'
git -C "$SR" show "$C2:TEST-DIFFERENCES.md" | grep -q 'a fixed table of synonyms' || fail 'the changed difference is not exported'
mkdir -p design; printf 'a screen\n' > 'design/a screen.txt'; g add -A; g commit -qm 'design'
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export with design/ failed'
C3=$(git -C "$SR" rev-parse refs/heads/main); [ "$(git -C "$SR" rev-parse "$C3^")" = "$C2" ] || fail 'design/ is not a fast-forward'
[ "$(tree "$C3" | tr ' ' '|')" = 'ARCHITECTURE.md|BASELINE.md|DECISIONS.md|GRADING-CHECKLIST.md|PRD.md|TEST-DIFFERENCES.md|design/a|screen.txt' ] || fail "the export is not R2's paths: $(tree "$C3")"
# set-up again: found, not made
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'a second spec-setup failed'
[ "$(grep -c '^gh repo create' "$T/gh/log")" = 1 ] && grep -q '^spec-repo owner/code-spec exists at=' .vid/tw/log || fail 'a second spec-setup did not find the repository'
# a public repository, and the code repository, refused
cp .vid/tw/settings "$T/set"
spec() { sed "s#^spec-repo: .*#spec-repo: $1#" "$T/set" > .vid/tw/settings; }
gh repo create owner/open-spec > /dev/null; spec owner/open-spec
if sh "$GS" spec-setup > "$T/out" 2>&1; then fail 'spec-setup took a public repository'; fi
grep -q 'exists and is not private' "$T/out" || fail 'the public repository is not named'
spec owner/code
if sh "$GS" spec-setup > "$T/out" 2>&1; then fail 'spec-setup took the code repository'; fi
grep -q 'names the code repository' "$T/out" || fail 'the code repository is not named'
[ "$(grep -c '^gh repo create' "$T/gh/log")" = 2 ] || fail 'spec-setup made a repository it should not'
exit 0
