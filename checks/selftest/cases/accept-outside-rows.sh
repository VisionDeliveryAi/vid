#!/bin/sh
# Purpose: selftest case — rows accepted before ViD kept records (FB-3 A4): round.sh accept --rows "<ids>" --outside "<words>", for rows in no
# published ticket, ids and ranges, on GitHub manual's toy (fixtures/accept.sh). Refused, and nothing written: with no words, no id, an id
# not in the inventory at the applied commit, a row of a published ticket, naming it, and with a commit. With them: each row, and each
# transition, accepted by ruling, its label ending that there is no evidence (FB-3 E1), no commit and no merges line, nothing posted, one event; a deploy-owed row and a seam owed; a row
# recorded or limited left, and said. The stage-ahead warning counts them no more. A row of a withdrawn ticket is taken. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-outside-rows: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'; D=.vid/decide; W='done before we used ViD'
gh_w0() { find .vid/decide .vid/tw -type f ! -path '*/tmp.*' -exec cksum {} + | sort | cksum; }
N2=$(gh_issue 'Step S03'); mn_ticket "$N2" S03 step ROW-006 > ".vid/tw/out/issue-$N2.md"; printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\nwithdrawn %s decision=abc at=2026-11-19T09:00:00Z\n' "$N2" "$N2" >> .vid/tw/log
printf 'row ROW-008 known-limit | stand-in: decision\nrow ROW-007 accepted-by-ruling | stand-in: decision\n' >> .vid/tw/handed; mkdir -p $D; touch $D/merges
# a row written to the working tree alone is not the team's: the inventory read is the applied commit's
sed 's/^ROW-020 |/ROW-099 | behavior | REQ-001 | anonymous | n\/a | A pending row. Fails if it does not hold. | REQ-001 | owed: spec-only — first stage | origin: REQ-001\nROW-020 |/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; grep -q '^ROW-099' INVENTORY.md || fail 'the toy pending row is not there'
ac_round accept --rows ROW-003 --outside ''; w0=$(gh_w0)
no() { _w=$1; shift; ac_round accept "$@"; grep -q "^refused .*$_w" "$T/out" && [ "$(gh_w0)" = "$w0" ] || fail "not refused ($_w), or something was written: $*"; }
no 'words' --rows ROW-003 --outside ''; no 'not in the inventory: ROW-099' --rows 'ROW-003 ROW-099' --outside "$W"; no "ROW-001 (ticket #$AC_N)" --rows 'ROW-001..ROW-003' --outside "$W"; no 'no row' --rows ' ' --outside "$W"
ac_round accept "$AC_N" "$AC_C" --rows ROW-003 --outside "$W"; [ "$RC" = 2 ] && [ "$(gh_w0)" = "$w0" ] || fail "with a commit beside the rows: exit $RC"
warn() { sh "$CHECKS/plan.sh" warnings S05 2> "$T/out" | grep 'not yet accepted' | sed 's/.*whose \([0-9]*\) tests are not.*/\1/' | head -n 1; }
ac_round read; b=$(warn); [ -n "$b" ] || fail 'the stage-ahead warning counts nothing on the toy'
ac_round accept --rows 'ROW-003..ROW-010, HOS-001 SEAM-001 DIF-003' --outside "$W"; [ "$RC" = 0 ] && grep -qx 'recorded 8 rows accepted outside ViD, by the owner'"'"'s words — ROW-003,ROW-004,ROW-005,ROW-006,ROW-009,ROW-010,HOS-001,SEAM-001' "$T/out" || fail "the record: exit $RC"
for x in 'left ROW-007: accepted already' 'left ROW-008: a known limit' 'left DIF-003: a record, not a test'; do grep -qx "$x" "$T/out" || fail "not said: $x"; done
for r in ROW-003 ROW-004 ROW-005 ROW-006 HOS-001; do grep -q "^row $r accepted-by-ruling | stand-in: owner at .*, words \"$W\"; evidence: none, accepted outside ViD\$" .vid/tw/handed && grep -qx "$r" $D/record || fail "$r is not accepted by ruling"; done
for r in ROW-004-T2 ROW-003 HOS-001; do awk -F'\t' -v r="$r" '$1 == r && $2 == "accepted by ruling" { f = 1 } END { exit !f }' $D/state && awk -F'\t' -v r="$r" '$2 == r && $3 == "accept" && $5 == "owner" { f = 1 } END { exit !f }' $D/rulings || fail "$r has no state or ruling"; done
for r in ROW-009 ROW-010 SEAM-001; do grep -q "^row $r owed | stand-in: owner at " .vid/tw/handed && ! grep -q "	$r	accept" $D/rulings || fail "$r is not owed"; done
[ ! -s $D/merges ] && [ ! -s $D/accepted-at ] && [ "$(ac_comments)" = 0 ] || fail 'rows alone wrote a merge, or posted'
[ "$(grep -c '^accepted-outside .*ticket=- rows=ROW-003,' .vid/metrics-events)" = 1 ] || fail 'the event is not there, once'
a=$(warn); [ "${a:-0}" -lt "$b" ] || fail "the warning still counts those rows: $b before, ${a:-0} after"
exit 0
