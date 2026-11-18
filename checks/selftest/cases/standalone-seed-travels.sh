#!/bin/sh
# Purpose: selftest case — a seed with its own `## ` headings, and its journey from a standalone create-prd into a project
# (0.26.10.29.3, R9, F44). The known-good PRD with a `## Background` heading inside its `## Seed` section (the seed's own)
# and a second seed-grounded mechanism (a third quotes words the seed never says, and keeps its own line): checks/prd.sh
# gives one advice line — the section ends at the seed's own heading,
# the seed goes to SEED.md with a `Seed:` pointer line — instead of one join-11 line per excerpt. The pointer form (the
# seed, headings and all, in SEED.md; `Seed: SEED.md (sha256 …)` in the header) passes; PRD.md and SEED.md moved together
# into a new folder pass there; PRD.md moved alone is refused for the missing seed, and eol.sh check reads SEED.md's line
# endings. Where skills/ is here, the import door, the standalone hand-back and init's adoption name SEED.md. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "standalone-seed-travels: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
run() { RC=0; "$@" > "$T/out" 2>&1 || RC=$?; }
G=$CHECKS/selftest/fixtures/prd-known-good.md
# the seed's own heading inside ## Seed, and a second mechanism grounded in the seed's words after it
awk '/^## Seed$/ { print; getline; print; print "## Background"; print ""; next }
  /^MECH-01 / { print; print "MECH-02 | G1 | Search expands occupational synonyms before matching. | stated: seed \"occupational synonyms\""
    print "MECH-03 | G1 | Alerts are sent by pigeon. | stated: seed \"sent by pigeon\""; next } { print }' "$G" > PRD.md
grep -q '^## Background$' PRD.md && grep -q '^MECH-02 ' PRD.md && grep -q '^MECH-03 ' PRD.md || fail 'the fixture was not made'
run sh "$CHECKS/prd.sh" PRD.md
[ "$RC" = 1 ] || fail "a seed cut short by its own heading passed ($RC)"
grep -q "join 11: the ## Seed section ends at the seed's own heading '## Background'" "$T/out" || fail 'no advice that the seed section ends early'
grep -q 'SEED.md' "$T/out" && grep -q 'Seed: SEED.md (sha256' "$T/out" || fail 'the advice does not say to use SEED.md and its Seed: line'
grep -q 'join 11 (MECH-0[12]): seed excerpt' "$T/out" && fail 'join 11 still fails line by line for the excerpts after the heading'
grep -q 'so 2 seed excerpt' "$T/out" || fail 'the advice does not count the two excerpts after the heading'
# words the seed never says, which the mechanism row itself quotes, are still their own line
grep -q 'join 11 (MECH-03): seed excerpt "sent by pigeon" does not appear verbatim' "$T/out" || fail 'an excerpt the seed never says lost its own line'
[ "$(grep -c '^GAP  join 11' "$T/out")" = 2 ] || fail 'not two join-11 lines (the advice, and MECH-03)'
grep -v '^MECH-03 ' PRD.md > x && mv x PRD.md
# the pointer form
awk '/^## Seed$/ { s = 1; next } s && /^## / && $0 != "## Background" { s = 0 } s { next } { print }' PRD.md > "$T/body"
awk '/^## Seed$/ { s = 1; next } s && /^## / && $0 != "## Background" { exit } s { print }' PRD.md > SEED.md
grep -q '^## Background$' SEED.md && grep -q 'occupational synonyms' SEED.md || fail 'SEED.md was not made'
H=$( (shasum -a 256 SEED.md 2>/dev/null || sha256sum SEED.md) | cut -d' ' -f1)
awk -v h="$H" 'NR == 1 { print; print ""; print "Seed: SEED.md (sha256 " h ")"; next } { print }' "$T/body" > PRD.md
run sh "$CHECKS/prd.sh" PRD.md; [ "$RC" = 0 ] || fail "the pointer form with its SEED.md was refused ($RC)"
mkdir -p "$T/project"; cp PRD.md SEED.md "$T/project/"
run sh "$CHECKS/prd.sh" "$T/project/PRD.md"; [ "$RC" = 0 ] || fail "PRD.md and SEED.md moved together were refused ($RC)"
mkdir -p "$T/alone"; cp PRD.md "$T/alone/"
run sh "$CHECKS/prd.sh" "$T/alone/PRD.md"; [ "$RC" = 1 ] && grep -q 'points at SEED.md, which does not exist beside the PRD' "$T/out" || fail "PRD.md moved without its SEED.md passed ($RC)"
( cd "$T/project" && awk '{ printf "%s\r\n", $0 }' SEED.md > s && mv s SEED.md && sh "$CHECKS/eol.sh" check > "$T/out" 2>&1 ) && fail 'eol.sh check passed a CR LF SEED.md'
grep -q 'SEED.md has Windows line endings' "$T/out" || fail 'eol.sh check does not name SEED.md'
S=$CHECKS/../skills
if [ -f "$S/vid-create-prd/SKILL.md" ] && [ -f "$S/vid-init/SKILL.md" ]; then
  grep -q 'its own `## ` headings' "$S/vid-create-prd/SKILL.md" || fail "the import door does not send a seed with its own headings to SEED.md"
  grep -q 'the PRD and its SEED.md' "$S/vid-create-prd/SKILL.md" || fail 'the standalone hand-back does not carry SEED.md'
  grep -q 'SEED.md' "$S/vid-init/SKILL.md" || fail "init's adoption does not take SEED.md"
fi
echo 'standalone-seed-travels: ok'
