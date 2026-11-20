#!/bin/sh
# Purpose: selftest case — an incorporation's new risks get test rows (IR I4). On I1's toy project the record sets one
# testable rule serving REQ-001 (D-003) and one that serves no requirement (D-004). After the spec text's commit, the
# rows: one NEW row derived from REQ-001, `owed: spec-only — ticket`, with `origin: incorporation <date> D-003`, and one
# `left:` line for D-004; `incorporate.sh check --base <before the amendment>` passes the whole map and prints
# `map: 4 changes, 1 left, 1 open`. Refused: a row derived from a decision id, a row with no incorporation origin, an
# origin naming a decision the amendment did not add, a decision with no row and no `left:` line, a row missing from the
# map, and rows under --text (the first part holds the spec text alone). A rule row, which has no derived-from field,
# carries `origin: incorporation <date> D-NNN REQ-NNN`: its requirement after the decision, never a D-id. Rows are placed
# by id, every kind: a second new row, a new rule row or a changed rule row off the map is refused; a changed row naming a
# D-id where its requirements go is refused; a new hostility row is its decision's row and needs the origin. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/p"; cd "$T/p"
fail() { echo "incorporate-rows: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
H=$CHECKS/incorporate.sh
git init -q
printf '.vid/\n' > .gitignore
printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | an item is stored once\nREQ-002 | functional | T1 | a run is written whole\n```\n' > PRD.md
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | items | (process) | n/a | an item is stored once | REQ-001 | owed: spec-only — ticket\nROW-002 | behavior | runs | (process) | n/a | a run is written whole | REQ-002 | owed: spec-only — ticket\nrule | RULE-009 | a run is never half written | grep -c half | 1 | owed: spec-only — ticket | origin: REQ-002\n```\n' > INVENTORY.md
printf '# Architecture\n\n| Module | Owns |\n|---|---|\n| `feed/store` | the stored items |\n' > ARCHITECTURE.md
printf '# DECISIONS\n\n## Log\n\n- **D-001** items are keyed by their source id | why: one key | enforced: convention | applies-to: REQ-001\n- **D-002** each run writes a table of its own | why: runs stay apart | enforced: convention\n' > DECISIONS.md
mkdir records
printf '# Feed store\n\nDecided: every item goes to one shared table, written by one writer at a time.\nThe writer logs in plain text.\nRetention is as REQ-009 says.\n' > records/feed-store.md
g add -A && g commit -qm toy
B=$(git rev-parse HEAD)
C=$(sh "$H" cite records/feed-store.md 2> "$T/out") || fail 'cite was refused'
# the first part: the spec text, landed
printf -- '- **D-003** one writer at a time writes the shared table | why: its one writer, %s | enforced: convention | applies-to: REQ-001\n- **D-004** the writer logs in plain text | why: its logs, %s | enforced: convention | scope: project\n' "$C" "$C" >> DECISIONS.md
sh "$H" mark D-002 D-003 > "$T/out" 2>&1 || fail 'the mark was refused'
cat > "$T/map" <<'X'
DECISIONS.md | D-003 | today: none | change: one writer at a time writes the shared table | record: "written by one writer at a time"
DECISIONS.md | D-004 | today: none | change: the writer logs in plain text | record: "The writer logs in plain text."
DECISIONS.md | D-002 | today: each run writes a table of its own | change: marked replaced-by: D-003 | record: "one shared table"
open: the record names REQ-009 for retention, which the spec does not hold
X
sh "$H" check "$T/map" --record "$C" --text > "$T/out" 2>&1 || fail 'check refused the spec text'
g add DECISIONS.md && g commit -qm 'the decisions commit'
# the rows, ratified: their lines join the map
awk '/^```$/ { print "ROW-003 | behavior | shared table | (process) | n/a | two writers never write the shared table at once | REQ-001 | owed: spec-only — ticket | origin: incorporation 2026-11-19 D-003" } { print }' INVENTORY.md > "$T/inv"; cp "$T/inv" INVENTORY.md
grep -q '^ROW-003 .*origin: incorporation 2026-11-19 D-003$' INVENTORY.md || fail 'the toy row was not written'
cp "$T/map" "$T/m0"
cat >> "$T/map" <<'X'
INVENTORY.md | ROW-003 | today: none | change: a row for the one-writer rule | record: "written by one writer at a time"
left: DECISIONS.md | D-004 | serves no requirement and sets no rule a row can test
X
sh "$H" check "$T/map" --record "$C" --base "$B" > "$T/out" 2>&1 || fail 'check refused the rows its map covers'
grep -qxF 'map: 4 changes, 1 left, 1 open' "$T/out" || fail "check does not print the whole map's counts"
# refused <what> <map> <word>: check refuses, its output naming <word>
refused() { if sh "$H" check "$2" --record "$C" --base "$B" ${4:-} > "$T/out" 2>&1; then fail "check passed $1"; fi; grep -qF -- "$3" "$T/out" || fail "the refusal of $1 does not name $3"; }
sed 's/| REQ-001 | owed: spec-only — ticket | origin: incorporation/| D-003 | owed: spec-only — ticket | origin: incorporation/' "$T/inv" > INVENTORY.md; refused 'a row derived from a decision id' "$T/map" ROW-003
sed 's/ | origin: incorporation 2026-11-19 D-003$//' "$T/inv" > INVENTORY.md; refused 'a row with no incorporation origin' "$T/map" ROW-003
sed 's/origin: incorporation 2026-11-19 D-003$/origin: incorporation 2026-11-19 D-001/' "$T/inv" > INVENTORY.md; refused 'an origin naming an old decision' "$T/map" D-001
cp "$T/inv" INVENTORY.md
grep -v '^left:' "$T/map" > "$T/m1"; refused 'a decision with no row and no left: line' "$T/m1" D-004
grep -v '^INVENTORY.md' "$T/map" > "$T/m2"; refused 'a row missing from the map' "$T/m2" INVENTORY.md
refused 'rows under --text' "$T/map" INVENTORY.md --text
sh "$H" check "$T/map" --record "$C" --base "$B" > "$T/out" 2>&1 || fail 'check refused the rows once restored'
# a rule row carries its requirement after the decision in its origin; a decision id there is refused. Every row kind is
# placed by its id, so the rule row needs a map line of its own
awk '/^```$/ { print "rule | RULE-001 | one writer holds the shared table | grep -c writer | 1 | owed: spec-only — ticket | origin: incorporation 2026-11-19 D-003 REQ-001" } { print }' "$T/inv" > "$T/inv2"; cp "$T/inv2" INVENTORY.md
refused 'a new rule row missing from the map' "$T/map" RULE-001
{ cat "$T/map"; echo 'INVENTORY.md | RULE-001 | today: none | change: a rule row for the one writer | record: "one writer at a time"'; } > "$T/mr"
sh "$H" check "$T/mr" --record "$C" --base "$B" > "$T/out" 2>&1 || fail 'check refused a rule row with its requirement after the decision'
sed 's/origin: incorporation 2026-11-19 D-003 REQ-001$/origin: incorporation 2026-11-19 D-003 D-004/' "$T/inv2" > INVENTORY.md; refused 'a rule row whose origin names a decision for its requirement' "$T/mr" RULE-001
sed 's/origin: incorporation 2026-11-19 D-003 REQ-001$/origin: incorporation 2026-11-19 D-003/' "$T/inv2" > INVENTORY.md; refused 'a rule row with no requirement in its origin' "$T/mr" RULE-001
sed 's/D-003$/D-003 REQ-001/' "$T/inv" > INVENTORY.md; refused 'a row whose origin goes past its decision' "$T/map" ROW-003
# a second new row, and a changed rule row, each left off the map
awk '/^```$/ { print "ROW-004 | behavior | shared table | (process) | n/a | a run waits for the writer | REQ-002 | owed: spec-only — ticket | origin: incorporation 2026-11-19 D-003" } { print }' "$T/inv" > INVENTORY.md; refused 'a second new row missing from the map' "$T/map" ROW-004
sed 's/a run is never half written/a run is never written in part/' "$T/inv" > INVENTORY.md; refused 'a changed rule row missing from the map' "$T/map" RULE-009
# a changed row naming a decision where its requirements go
sed 's/| an item is stored once | REQ-001 |/| an item is stored once | REQ-001 D-003 |/' "$T/inv" > INVENTORY.md
{ cat "$T/map"; echo 'INVENTORY.md | ROW-001 | today: from REQ-001 | change: from REQ-001 and D-003 | record: "one shared table"'; } > "$T/mc"; refused 'a changed row derived from a decision id' "$T/mc" ROW-001
# any row kind is its decision's row, and carries the incorporation's origin
HR='hostility | HOS-001 | the writer logs a secret | protects: ROW-003 | disable: plain-log-filter | owed: spec-only — ticket | origin: incorporation 2026-11-19 D-004'
awk -v r="$HR" '/^```$/ { print r } { print }' "$T/inv" > INVENTORY.md
{ grep -v '^left:' "$T/map"; echo 'INVENTORY.md | HOS-001 | today: none | change: a hostility row for the plain logs | record: "logs in plain text"'; } > "$T/mh"
sh "$H" check "$T/mh" --record "$C" --base "$B" > "$T/out" 2>&1 || fail "check refused a hostility row as its decision's row"
awk -v r="${HR% | origin:*}" '/^```$/ { print r } { print }' "$T/inv" > INVENTORY.md; refused 'a new hostility row with no incorporation origin' "$T/mh" HOS-001
echo 'incorporate-rows: ok'
