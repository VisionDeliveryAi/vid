#!/bin/sh
# Purpose: selftest case — the open-question count a hand-back quotes is the
# court's (0.26.10.29.3, R4). checks/prd.sh --report on the known-good
# fixture, its `## Open decisions` opening with the template's comment (which
# names `VID-QUESTION: (OQ-1) …` and `(OQ-2) A-NNN` as examples), prints
# `open-OQs=1`: the one open carrier line, never the comment's examples nor
# the RESOLVED one. A question an agent raised, recorded as a carrier in a
# dated append, makes it `open-OQs=2` and the court still passes. Where ViD's
# skills are beside checks/ (not in a project), the hand-backs of vid-init,
# vid-stage, vid-add and vid-create-prd quote that field, and vid-create-prd
# carries the rule that a raised question becomes a carrier. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "court-counts-open-oq: $*" >&2; exit 1; }
cat > comment.txt <<'EOF'
<!-- Blocking product questions carried as markers, each with a stable
     carrier id: `VID-QUESTION: (OQ-1) …`. The literal token
     `VID-QUESTION:` — colon included — is what checks/coverage.sh
     counts; the carrier id follows it. A must-never-break question asks
     exactly one ViD decision a T0 item rests on and names it after its
     id: `VID-QUESTION: (OQ-2) A-NNN — <the question>` — one decision,
     one carrier. -->

EOF
awk 'FNR == NR { c = c $0 "\n"; next } { print } /^## Open decisions$/ { getline; print; printf "%s", c }' comment.txt "$FIXTURES/prd-known-good.md" > PRD.md
[ "$(grep -c 'VID-QUESTION: (OQ-' PRD.md)" -eq 3 ] || fail 'the fixture does not hold the comment'"'"'s two examples and the one carrier'
count() { sh "$COURT" PRD.md --report 2>/dev/null | sed -n 's/.* open-OQs=\([0-9][0-9]*\) .*/\1/p'; }
[ "$(count)" = 1 ] || fail "one open carrier, but the court reports open-OQs=$(count)"
sh "$COURT" PRD.md --report 2>/dev/null | grep -q ' resolved-OQs=1 ' || fail 'the resolved carrier is not counted as resolved'
printf '\n### 2026-10-01 (a question the inventory pass raised)\n\nVID-QUESTION: (OQ-3) Does a paused subscriber keep their saved searches?\n' >> PRD.md
[ "$(count)" = 2 ] || fail "two open carriers, but the court reports open-OQs=$(count)"
sh "$COURT" PRD.md >/dev/null 2>&1 || fail 'the court refuses a carrier recorded in a dated append'
# the skills' hand-backs quote the court's field (ViD's own repository only)
S="$CHECKS/../skills"
if [ -d "$S/vid-init" ]; then
  sec() { awk -v h="$2" 'index($0, h) == 1 { on = 1; next } on && /^#/ { exit } on' "$S/$1/SKILL.md" | tr '\n' ' ' | tr -s ' '; }
  sec vid-init '## 8. Hand back' | grep -qF 'open-OQs=' || fail "vid-init's hand-back does not quote the court's open-OQs="
  sec vid-stage '## Hand back' | grep -qF 'open-OQs=' || fail "vid-stage's hand-back does not quote the court's open-OQs="
  sec vid-add '## 5. Hand back' | grep -qF 'open-OQs=' || fail "vid-add's hand-back does not quote the court's open-OQs="
  sec vid-create-prd '### 12. Pause 3' | grep -qF 'open-OQs=' || fail "vid-create-prd's hand-back does not quote the court's open-OQs="
  tr '\n' ' ' < "$S/vid-create-prd/SKILL.md" | tr -s ' ' | grep -qF 'becomes an open carrier at once, `VID-QUESTION: (OQ-n)' || fail 'vid-create-prd does not say a raised question becomes a carrier at once'
fi
exit 0
