#!/bin/sh
# Purpose: selftest case — the PRD writer after the final ratification (FB-1 A2), on the 0.9.4 good fixture. (1) `findings`
# with a dated heading, a final review's line and one row writes exactly that heading, its findings block and its line
# at the end of `## Findings`, the court green; a repair append that then says `review: final, round 1, 0 findings, see
# <that heading>` passes the court. (2) An `append` carrying an AMENDED row and an answer, with its review line, writes one
# dated section holding both blocks and the line, and `checks/prd.sh --effective` gives the amended row. (2b) An `append` with a `carrier` line writes the carrier
# into its section, and a second call resolves it there (`resolve`), the court green. (3) In a
# repository with the commit hooks: an `append` alone is refused at its commit by the hook's append-review check; a second
# call with a findings row and a `review` line leaves one section holding both, and the commit of PRD.md passes. Env: CHECKS.
set -eu
fail() { echo "prd-apply-append: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
[ -f "$CHECKS/prd-apply.sh" ] || fail 'checks/prd-apply.sh is missing: no writer applies a sitting'
FX="$CHECKS/selftest/fixtures/prd-094-good.md"
apply() { sh "$CHECKS/prd-apply.sh" PRD.md "$1" --date 2026-08-30 > out.txt 2>&1 || { cat out.txt >&2; fail "$2 was refused"; }; }
# (1) a final review's record, then its repair append
cp "$FX" PRD.md
H='2026-08-30 — final review'; RV='review: final, round 1, 1 findings, read: PRD.md'
F6='F-06 | final | advisory | REQ-012 | noted | evidence: the footer names no reply time'
printf 'findings "%s" "%s"\nrow %s\nend\n' "$H" "$RV" "$F6" > e1.txt
apply e1.txt 'the final review record'
awk -v h="### $H" -v f="$F6" -v rv="$RV" '/^## Ratifications$/ { print h; print ""; print "```vid-prd-findings"; print f; print "```"; print ""; print rv; print "" } { print }' "$FX" > want.md
cmp -s want.md PRD.md || { diff want.md PRD.md >&2 || true; fail 'findings wrote other than its heading, block and line under ## Findings'; }
sh "$CHECKS/prd.sh" PRD.md >/dev/null 2>&1 || fail 'the court is not green after the final review record'
A12='REQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | phase: pilot | feature: FEAT-03 | arms: 1 retained, 2 retained'
printf 'append "final review repairs" "review: final, round 1, 0 findings, see %s"\nrow %s\nend\n' "$H" "$A12" > e2.txt
apply e2.txt 'the repair append'
sh "$CHECKS/prd.sh" PRD.md >/dev/null 2>&1 || fail "the court refused the repair append's see line"
# (2) an append with an AMENDED row and an answer
cp "$FX" PRD.md
A10='A-010 | human | 2026-08-30 | Q: may the unsubscribe take effect at the next digest? | A: yes — it stops every digest from the next one | settles: REQ-002'
R2='REQ-002 AMENDED | functional | T1 | Every digest carries a working one-click unsubscribe that stops all digests for that address from the next digest. | fail-if: a digest arrives after the next one following its unsubscribe, or the unsubscribe link requires a sign-in | serves: consent exit — the trust floor of an email product | authority: authoritative | source: seed, A-010 | covers: DIM-consent | phase: pilot | feature: FEAT-03 | arms: 1 strengthened, 2 retained'
printf 'append "owner answer" "review: delta, round 1, 0 findings"\nrow %s\nrow %s\nend\n' "$R2" "$A10" > e3.txt
apply e3.txt 'the append'
{ cat "$FX"; printf '\n### 2026-08-30 (owner answer)\n\n```vid-prd-answers\n%s\n```\n\n```vid-prd\n%s\n```\n\nreview: delta, round 1, 0 findings\n' "$A10" "$R2"; } > want.md
cmp -s want.md PRD.md || { diff want.md PRD.md >&2 || true; fail 'append wrote other than one dated section holding both blocks and the review line'; }
sh "$CHECKS/prd.sh" --effective PRD.md | grep -qxF "$(printf '%s\n' "$R2" | sed 's/^REQ-002 AMENDED |/REQ-002 |/')" || fail '--effective does not give the amended row'
# (2b) an append carrying an open carrier, resolved in a second call
cp "$FX" PRD.md
Q4='VID-QUESTION: (OQ-4) Does a digest held while the address is paused go out later?'
printf 'append "owner question"\ncarrier %s\nend\n' "$Q4" > e6.txt
apply e6.txt 'the append with a carrier'
{ cat "$FX"; printf '\n### 2026-08-30 (owner question)\n\n%s\n' "$Q4"; } > want.md
cmp -s want.md PRD.md || { diff want.md PRD.md >&2 || true; fail 'append wrote other than its section with the carrier line'; }
A10='A-010 | human | 2026-08-30 | Q: does a digest held while the address is paused go out later? | A: no — a held digest is dropped | settles: REQ-002'
printf 'append "owner answer" "review: delta, round 1, 0 findings"\nrow %s\nend\nresolve OQ-4 A-010\n' "$A10" > e7.txt
apply e7.txt 'the answer and the resolve'
grep -qx 'RESOLVED: (OQ-4) A-010 — Does a digest held while the address is paused go out later?' PRD.md || fail 'the carrier in the append was not resolved'
grep -q '^VID-QUESTION: (OQ-4)' PRD.md && fail 'the open carrier is still there'
sh "$CHECKS/prd.sh" PRD.md >/dev/null 2>&1 || fail 'the court is not green after the resolve'
# (3) the append opened, then finished in a second call, through the commit hooks
mkdir repo && cd repo && git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/hooks app
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh prd-consolidate.sh eol.sh lawfiles lib; do [ ! -e "$CHECKS/$c" ] || cp -R "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
cp "$FX" PRD.md; printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
A10='A-010 | human | 2026-08-30 | Q: may a subscriber pause digests? | A: yes — a pause holds every digest until resumed | settles: REQ-030'
R30='REQ-030 | functional | T2 | A subscriber can pause all digests and resume them. | fail-if: a digest arrives while its address is paused | serves: a subscriber away keeps the searches without the mail | authority: authoritative | source: A-010 | phase: pilot | feature: FEAT-03'
printf 'append "/vid add"\nrow %s\nrow %s\nend\n' "$A10" "$R30" > ../e4.txt
apply ../e4.txt 'the opened append'
MSG='add a pause

Owner: "yes, a pause holds every digest until resumed"
Decisions: none — nothing surprising'
g add PRD.md
if g commit -qm "$MSG" > ../c1.txt 2>&1; then fail 'the hook took an append with no review record'; fi
grep -q 'no record of its delta review' ../c1.txt || { cat ../c1.txt >&2; fail "the first commit was refused, but not by the append-review check"; }
F6='F-06 | review | advisory | REQ-030 | noted | evidence: the pause names no longest hold'
printf 'row %s\nreview "review: delta, round 1, 1 findings"\n' "$F6" > ../e5.txt
apply ../e5.txt 'the findings row and the review line'
S=$(awk '/^### 2026-08-30 \(\/vid add\)$/ { on = 1 } on' PRD.md)
[ "$(grep -c '^### ' "$FX")" -eq "$(( $(grep -c '^### ' PRD.md) - 1 ))" ] || fail 'the second call made a section of its own'
printf '%s\n' "$S" | grep -qxF "$F6" && printf '%s\n' "$S" | grep -qx 'review: delta, round 1, 1 findings' && printf '%s\n' "$S" | grep -qxF "$R30" \
  || { printf '%s\n' "$S" >&2; fail 'the section does not hold the rows, the finding and the review line'; }
g add PRD.md
g commit -qm "$MSG" > ../c2.txt 2>&1 || { cat ../c2.txt >&2; fail 'the commit of the finished append was refused'; }
echo 'prd-apply-append: ok'
