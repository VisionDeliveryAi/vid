#!/bin/sh
# Purpose: selftest case — a court run directly refuses a spec file with Windows line endings (0.26.10.29.3, R9, F53),
# with eol.sh's line-endings line, never misreading it and never stripping its carriage returns. The known-good PRD saved
# CR LF and run through checks/prd.sh; an INVENTORY.md saved CR LF through checks/inventory.sh; a STAGES.md saved CR LF
# through checks/stages.sh (its court, its counts and `current`, which reads STAGES.md alone: a fenced STAGE-0 saved CR LF
# is refused, never read as stage 1); the SEED.md a PRD's `Seed:` line points at, saved CR LF, through checks/prd.sh. The
# same files with LF line endings are not refused for their line endings. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "court-refuses-crlf: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
line() { echo "ViD: refused — $1 has Windows line endings (CR LF), which ViD's checks cannot read. Save it with LF line endings; .gitattributes keeps git from adding them back (sh checks/eol.sh write)."; }
crlf() { awk '{ printf "%s\r\n", $0 }' "$1" > "$1.x"; mv "$1.x" "$1"; }
lf() { tr -d '\r' < "$1" > "$1.x"; mv "$1.x" "$1"; }
run() { RC=0; "$@" > "$T/out" 2>&1 || RC=$?; }
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
run sh "$CHECKS/prd.sh" PRD.md; [ "$RC" = 0 ] || fail "the known-good PRD with LF line endings did not pass ($RC)"
crlf PRD.md; cp PRD.md "$T/prd.crlf"
run sh "$CHECKS/prd.sh" PRD.md; [ "$RC" = 1 ] && grep -qxF "$(line PRD.md)" "$T/out" || fail "prd.sh read a CR LF PRD.md without the line-endings refusal ($RC)"
grep -q '^prd: items=' "$T/out" && fail 'prd.sh reported on the CR LF file it refused'
cmp -s PRD.md "$T/prd.crlf" || fail 'prd.sh changed the file it refused'
lf PRD.md
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '# Inventory\n\n```vid-inventory\nROW-001 | behavior | list | user | n/a | the list shows ten | REQ-001 | owed: later\n```\n' > INVENTORY.md
run sh "$CHECKS/inventory.sh"; grep -q 'Windows line endings' "$T/out" && fail 'inventory.sh refused an LF INVENTORY.md for its line endings'
crlf INVENTORY.md
run sh "$CHECKS/inventory.sh"; [ "$RC" = 1 ] && grep -qxF "$(line INVENTORY.md)" "$T/out" || fail "inventory.sh read a CR LF INVENTORY.md without the line-endings refusal ($RC)"
grep -q '^inventory: rows=' "$T/out" && fail 'inventory.sh reported on the CR LF file it refused'
lf INVENTORY.md
printf '# Stages\n\n```vid-stages\nSTAGE-1 | first | features: -\n```\n' > STAGES.md
run sh "$CHECKS/stages.sh" check; grep -q 'Windows line endings' "$T/out" && fail 'stages.sh refused an LF STAGES.md for its line endings'
crlf STAGES.md
for c in check counts current; do
  run sh "$CHECKS/stages.sh" $c; [ "$RC" = 1 ] && grep -qxF "$(line STAGES.md)" "$T/out" || fail "stages.sh $c read a CR LF STAGES.md without the line-endings refusal ($RC)"
done
# a subcommand that reads STAGES.md without the other spec files: a fenced STAGE-0 saved CR LF is refused, not read as stage 1
printf '# Stages\n\n```vid-stages\nSTAGE-0 | skeleton | technical\nSTAGE-1 | first | features: -\n```\n' > STAGES.md
run sh "$CHECKS/stages.sh" current; [ "$RC" = 0 ] && [ "$(cat "$T/out")" = 0 ] || fail "stages.sh current does not read an LF STAGE-0 as stage 0 ($RC: $(cat "$T/out"))"
crlf STAGES.md
run sh "$CHECKS/stages.sh" current; [ "$RC" = 1 ] && grep -qxF "$(line STAGES.md)" "$T/out" || fail "stages.sh current read a CR LF STAGE-0 without the line-endings refusal ($RC: $(cat "$T/out"))"
rm -f STAGES.md
# the seed file the PRD's Seed: line points at: saved CR LF, its hash on the line, the PRD itself LF
awk '/^## Seed$/ { s = 1; next } s && /^## / { exit } s { print }' PRD.md > SEED.md; crlf SEED.md
H=$( (shasum -a 256 SEED.md 2>/dev/null || sha256sum SEED.md) | cut -d' ' -f1)
awk -v h="$H" 'NR == 1 { print; print ""; print "Seed: SEED.md (sha256 " h ")"; next } /^## Seed$/ { s = 1; next } s && /^## / { s = 0 } s { next } { print }' PRD.md > PRD.x; mv PRD.x PRD.md
run sh "$CHECKS/prd.sh" PRD.md; [ "$RC" = 1 ] && grep -qxF "$(line SEED.md)" "$T/out" || fail "prd.sh read a CR LF SEED.md without the line-endings refusal ($RC)"
grep -q '^prd: items=' "$T/out" && fail 'prd.sh reported on a PRD whose seed file it refused'
lf SEED.md; H=$( (shasum -a 256 SEED.md 2>/dev/null || sha256sum SEED.md) | cut -d' ' -f1)
sed "s/^Seed: SEED.md (sha256 .*/Seed: SEED.md (sha256 $H)/" PRD.md > PRD.x; mv PRD.x PRD.md
run sh "$CHECKS/prd.sh" PRD.md; [ "$RC" = 0 ] || fail "the same PRD with an LF SEED.md did not pass ($RC)"
echo 'court-refuses-crlf: ok'
