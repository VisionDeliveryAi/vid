#!/bin/sh
# Purpose: selftest case — TW writes only on the owner's go, with its settings, W1 (v0.26.10.12.3
# R1). On the clean toy `writer.sh gate` passes. Each of these is refused, named in its own line: no publish-approved
# event; an approval in words not the ratification's; settings with no repo:, no spec-repo:, a spec-repo: naming the
# code repository, no labels-prefix: line, an open-tickets: of 0 or in words; an uncommitted change to PRD.md,
# DECISIONS.md, BASELINE.md, design/ or a golden set. An empty labels-prefix: and no open-tickets: line pass. The gate
# closes after a committed INVENTORY.md change (stage 1's R8) and opens after its new ratification, with its own
# publish-approved words; two things missing give two lines. github.sh tw-post and tw-close ask the gate first:
# with S02's ticket #2 open and S03's written, RUN-STATE's block edited with no recorded change shuts
# the gate, and tw-post posts nothing and tw-close withdraws nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-gate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
gate() { RC=0; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || RC=$?; }
refused() { gate; [ "$RC" = 1 ] || fail "the gate passed with $2"; grep -qF "writer: gate — $1" "$T/out" || fail "not named: $1"; }
gate; [ "$RC" = 0 ] || fail 'the gate refuses the clean toy'
grep -q '^writer: gate open' "$T/out" || fail 'the open gate says nothing'
# the approval: missing, then not the ratification's words
cp .vid/metrics-events "$T/ev"; grep -v '^publish-approved ' "$T/ev" > .vid/metrics-events
refused 'no publish-approved event' 'no approval'
printf 'publish-approved words="go ahead" at=2026-11-03T11:00:00Z\n' >> .vid/metrics-events
refused "the newest publish-approved event's words (\"go ahead\")" 'an approval in other words'; cp "$T/ev" .vid/metrics-events
# the settings
cp .vid/tw/settings "$T/set"
set_() { grep -v "^$1:" "$T/set" > .vid/tw/settings || true; [ -z "$2" ] || printf '%s\n' "$2" >> .vid/tw/settings; }
set_ repo ''; refused 'the settings name no repo:' 'no repo:'
set_ spec-repo ''; refused 'the settings name no spec-repo:' 'no spec-repo:'
set_ spec-repo 'spec-repo: owner/code'; refused 'spec-repo: names the code repository owner/code' 'the code repository as the spec repository'
set_ labels-prefix ''; refused 'the settings have no labels-prefix: line' 'no labels-prefix:'
set_ open-tickets 'open-tickets: 0'; refused "open-tickets: '0' is not a whole number" 'a limit of 0'
set_ open-tickets 'open-tickets: two'; refused "open-tickets: 'two' is not a whole number" 'a limit in words'
set_ open-tickets ''; gate; [ "$RC" = 0 ] || fail 'the gate refuses settings with no open-tickets: line'
grep -q 'open-tickets: no limit' "$T/out" || fail 'no limit is not said'
cp "$T/set" .vid/tw/settings
# an uncommitted change to an exported or quoted file
for f in PRD.md DECISIONS.md BASELINE.md; do printf '\n' >> "$f"; refused "$f has an uncommitted change" "an uncommitted $f"; git checkout -q "$f"; done
mkdir -p design; printf 'a\n' > design/a; refused 'design/ has an uncommitted change' 'an uncommitted design/'; rm -r design
printf 'x\n' >> tests/invariants/golden/synonyms.golden; refused 'tests/invariants/golden/synonyms.golden has an uncommitted change' 'a changed golden set'
git checkout -q tests/invariants/golden/synonyms.golden
gate; [ "$RC" = 0 ] || fail 'the gate refuses the restored toy'
# a ratified file changed: the gate closes, and opens after its new ratification with its own words
sed 's/one digest a day, holding only jobs/one digest each day, holding only jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam 'ROW-001 amended'
refused 'the plan is not ratified' 'INVENTORY.md changed after the ratification'
sh "$CHECKS/planner.sh" review --in "$T/none" > /dev/null; sh "$CHECKS/planner.sh" page > /dev/null 2>&1; sh "$CHECKS/planner.sh" ratify --words 'Yes, the amended row too' > /dev/null
refused "the newest publish-approved event's words (\"Yes, publish it\")" 'the old approval after a new ratification'
printf 'publish-approved words="Yes, the amended row too" at=2026-11-03T12:00:00Z\n' >> .vid/metrics-events
gate; [ "$RC" = 0 ] || fail 'the gate stays closed after the new ratification and its go'
# two things missing: two lines
grep -v '^repo:' "$T/set" > .vid/tw/settings; printf '\n' >> PRD.md; gate; [ "$RC" = 1 ] || fail 'the gate passed with two things missing'
[ "$(grep -c '^writer: gate — ' "$T/out")" -ge 3 ] || fail 'PRD.md changed and no repo: are not named in their own lines'
# tw-post and tw-close ask the gate first: the block edited after S03's ticket was written, with no recorded change
cp "$T/set" .vid/tw/settings; git checkout -q PRD.md; tw_skel || fail 'the skeleton round failed'
tw_start S02 && tw_post step S02 || fail "S02's ticket failed"; tw_start S03 && F3=$(sh "$CHECKS/writer.sh" write step S03 2> "$T/out") || fail "S03's ticket was not written"
pt_rs 's/^\(step S05 | name: \)synonym-aware search/\1search by other names/'; refused 'the plan is not ratified' 'the block edited with no recorded change'
if sh "$CHECKS/github.sh" tw-post "$F3" > "$T/out" 2>&1; then fail 'tw-post published with the gate shut'; fi
grep -q 'the gate is shut' "$T/out" && [ ! -d "$T/gh/issues/3" ] && ! grep -q '^published 3 ' .vid/tw/log || fail 'tw-post did not refuse by the gate, or #3 was made'
if sh "$CHECKS/github.sh" tw-close 2 > "$T/out" 2>&1; then fail 'tw-close withdrew #2 with the gate shut'; fi
grep -q 'the gate is shut' "$T/out" && [ "$(cat "$T/gh/issues/2/state")" = OPEN ] && ! grep -q '^withdrawn 2 ' .vid/tw/log || fail 'tw-close did not refuse by the gate, or #2 was withdrawn'
exit 0
