#!/bin/sh
# Purpose: selftest case — /vid incorporate's map against its amendment (IR I1). On a toy project, a toy record committed
# in its repository sets two rules, replaces one decision (D-002), changes no promise and names one id the spec lacks
# (REQ-009). `incorporate.sh cite` gives the record's cite, `<path>@<12-hex commit>`, and refuses a path not committed or
# changed since. The amendment holds two new decision lines, each citing the record, `enforced: convention`, the old line
# marked, and no PRD append; `incorporate.sh check --text` (the first part, the spec text) passes it and prints
# `map: 3 changes, 0 left, 1 open`. Refused: a change missing from the map (a decision line, ARCHITECTURE.md, a PRD
# append), a new decision line without the cite, one whose enforced: is not convention, a change line naming a line the
# amendment leaves as it was, a map line of no form, a cite of neither form, a symlink's cite, an old line whose words change,
# a removed line, a second requirement off the map (PRD.md is placed by REQ id). --record may repeat: a new line's why:
# holds any one cite. PRD.md is placed by item id, a trailing AMENDED taken off, every prefix of the grammar (INV- among
# them). A tab inside an old line's words does not make a mark-only change read as a change of its words. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/p"; cd "$T/p"
fail() { echo "incorporate-map: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
H=$CHECKS/incorporate.sh
git init -q
printf '.vid/\n' > .gitignore
printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | an item is stored once\nREQ-002 | functional | T1 | a run is written whole\n```\n' > PRD.md
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | items | (process) | n/a | an item is stored once | REQ-001 | owed: spec-only — ticket\nROW-002 | behavior | runs | (process) | n/a | a run is written whole | REQ-002 | owed: spec-only — ticket\n```\n' > INVENTORY.md
printf '# Architecture\n\n| Module | Owns |\n|---|---|\n| `feed/store` | the stored items |\n' > ARCHITECTURE.md
printf '# DECISIONS\n\n## Log\n\n- **D-001** items are keyed by their source id | why: one key | enforced: convention | applies-to: REQ-001\n- **D-002** each run writes a table of its own | why: runs stay apart | enforced: convention\n' > DECISIONS.md
mkdir records
printf '# Feed store\n\nDecided: every run writes one shared table, in place of a table per run.\nThe shared table has one writer.\nRetention is as REQ-009 says.\n' > records/feed-store.md
g add -A && g commit -qm toy
# the cite: committed and unchanged, else refused
C=$(sh "$H" cite records/feed-store.md 2> "$T/out") || fail 'cite of a committed record was refused'
[ "$C" = "records/feed-store.md@$(git rev-parse HEAD | cut -c1-12)" ] || fail "the cite is not <path>@<12-hex HEAD>: $C"
printf 'draft\n' > records/new.md
if sh "$H" cite records/new.md > "$T/out" 2>&1; then fail 'cite of a record not committed was not refused'; fi
printf 'more\n' >> records/feed-store.md
if sh "$H" cite records/feed-store.md > "$T/out" 2>&1; then fail 'cite of a record changed since its commit was not refused'; fi
git checkout -q records/feed-store.md; rm records/new.md
# a symlink is no record; a second record gives a second cite
ln -s feed-store.md records/link.md; printf '# Feed writer\n\nOne writer at a time.\n' > records/second.md; g add records && g commit -qm 'two more'
if sh "$H" cite records/link.md > "$T/out" 2>&1; then fail 'cite of a symlink was not refused'; fi
C2=$(sh "$H" cite records/second.md 2> "$T/out") || fail 'cite of the second record was refused'
# the amendment: two new lines citing the record, the old line marked
printf -- '- **D-003** every run writes one shared table | why: the shared table, %s | enforced: convention | applies-to: REQ-002\n- **D-004** the shared table has one writer | why: its one writer, %s | enforced: convention | applies-to: REQ-002\n' "$C" "$C" >> DECISIONS.md
sh "$H" mark D-002 D-003 > "$T/out" 2>&1 || fail 'the mark was refused'
cat > "$T/map" <<'X'
# the map: the spec text
DECISIONS.md | D-003 | today: none | change: every run writes one shared table | record: "one shared table, in place of a table per run"
DECISIONS.md | D-004 | today: none | change: the shared table has one writer | record: "The shared table has one writer."

DECISIONS.md | D-002 | today: each run writes a table of its own | change: marked replaced-by: D-003 | record: "in place of a table per run"
open: the record names REQ-009 for retention, which the spec does not hold
X
sh "$H" check "$T/map" --record "$C" --text > "$T/out" 2>&1 || fail 'check refused the amendment its map covers'
grep -qxF 'map: 3 changes, 0 left, 1 open' "$T/out" || fail "check does not print the map's counts"
[ "$(grep -c "why: .*$C" DECISIONS.md)" = 2 ] || fail 'the two new lines do not both cite the record'
git diff --quiet HEAD -- PRD.md || fail 'the amendment appends to the PRD'
# refused <what>: check refuses, its output naming <word>
refused() { if sh "$H" check "$2" --record "$C" --text > "$T/out" 2>&1; then fail "check passed $1"; fi; grep -qF -- "$3" "$T/out" || fail "the refusal of $1 does not name $3"; }
cp DECISIONS.md "$T/dec"
grep -v '| D-004 |' "$T/map" > "$T/m1"; refused 'a decision line missing from the map' "$T/m1" D-004
sed 's/| why: its one writer, [^|]*|/| why: its one writer |/' "$T/dec" > DECISIONS.md; refused 'a new line without the cite' "$T/map" D-004
sed 's/its one writer, \([^|]*\)| enforced: convention/its one writer, \1| enforced: tests\/invariants\/x.sh/' "$T/dec" > DECISIONS.md; refused 'a new line enforced by a test' "$T/map" convention
cp "$T/dec" DECISIONS.md
printf '\n## Appends\n\nREQ-003 | functional | T1 | a run is kept a week\n' >> PRD.md; refused 'a PRD append missing from the map' "$T/map" PRD.md
git checkout -q PRD.md
printf '| `feed/writer` | the one writer |\n' >> ARCHITECTURE.md; refused 'an ARCHITECTURE.md change missing from the map' "$T/map" ARCHITECTURE.md
git checkout -q ARCHITECTURE.md
{ cat "$T/map"; echo 'DECISIONS.md | D-001 | today: keyed by source id | change: none | record: "none"'; } > "$T/m2"; refused 'a change line naming a line left as it was' "$T/m2" D-001
{ cat "$T/map"; echo 'DECISIONS.md, a stray note'; } > "$T/m3"; refused 'a map line of no form' "$T/m3" 'a stray note'
if sh "$H" check "$T/map" --record records/feed-store.md --text > "$T/out" 2>&1; then fail 'check passed a cite of neither form'; fi
# an old line's words never change, and no line is removed, map line or not
{ cat "$T/map"; echo 'DECISIONS.md | D-001 | today: keyed by source id | change: keyed by name | record: "none"'; } > "$T/m4"
sed 's/items are keyed by their source id/items are keyed by their name/' "$T/dec" > DECISIONS.md; refused "an old line whose words change" "$T/m4" 'D-001'
grep -v 'D-001\*\*' "$T/dec" > DECISIONS.md; refused 'a removed decision line' "$T/m4" 'D-001'
cp "$T/dec" DECISIONS.md
# PRD.md is placed by requirement: each new requirement needs its own map line
printf '\n## Appends\n\n```vid-prd\nREQ-003 | functional | T1 | a run is kept a week\nREQ-004 | functional | T1 | a run is kept whole\n```\n' >> PRD.md
{ cat "$T/map"; echo 'PRD.md | REQ-003 | today: none | change: a run is kept a week | record: "kept a week"'; } > "$T/m5"; refused 'a second requirement missing from the map' "$T/m5" REQ-004
git checkout -q PRD.md
# an amended requirement is placed by its id, AMENDED taken off; every item prefix of the grammar is placed (INV- here)
printf '\n## Appends\n\n```vid-prd\nREQ-002 AMENDED | functional | T1 | a run is written whole, once\n```\n' >> PRD.md
refused 'an amended requirement missing from the map' "$T/map" REQ-002
{ cat "$T/map"; echo 'PRD.md | REQ-002 | today: a run is written whole | change: a run is written whole, once | record: "one shared table"'; } > "$T/m6"
sh "$H" check "$T/m6" --record "$C" --text > "$T/out" 2>&1 || fail 'check refused an amended requirement named on the map'
git checkout -q PRD.md
printf '\n## Appends\n\n```vid-prd\nREQ-003 | functional | T1 | a run is kept a week\nINV-001 | invariant | T0 | no run is lost\n```\n' >> PRD.md; refused 'a new invariant missing from the map' "$T/m5" INV-001
git checkout -q PRD.md
# several cites: a new line passes when its why: holds any one of them
sed "s|its one writer, $C|its one writer, $C2|" "$T/dec" > DECISIONS.md
sh "$H" check "$T/map" --record "$C" --record "$C2" --text > "$T/out" 2>&1 || fail 'check refused a new line citing the second of two records'
cp "$T/dec" DECISIONS.md
sh "$H" check "$T/map" --record "$C" --text > "$T/out" 2>&1 || fail 'check refused the amendment once restored'
# a tab inside an old line's words: a mark-only change still reads as a mark
printf -- '- **D-009** runs are kept\tapart | why: one key | enforced: convention | applies-to: REQ-001\n' >> DECISIONS.md; g add -A && g commit -qm 'a line with a tab'
sh "$H" mark D-009 D-003 > "$T/out" 2>&1 || fail 'the mark on a line holding a tab was refused'
printf 'DECISIONS.md | D-009 | today: runs kept apart | change: marked replaced-by: D-003 | record: "in place of a table per run"\n' > "$T/m7"
sh "$H" check "$T/m7" --record "$C" --text > "$T/out" 2>&1 || fail 'check read a mark-only change to a line holding a tab as a change of its words'
echo 'incorporate-map: ok'
