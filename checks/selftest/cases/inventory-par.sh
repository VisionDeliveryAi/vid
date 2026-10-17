#!/bin/sh
# Purpose: selftest case — the par gate and the closed deferral vocabulary
# (v0.9.2 spec 3.2, R3/R4; §7.1). The fixture is a toy product's init
# inventory in the pre-0.9.2 grammar, of the shape a real init produced (26
# rows, 4 materialised, 22 owed with prose reasons; F1/F2): (1) without a
# grammar line it replays through inventory.sh with the pre-0.9.2 output —
# the pinned summary line, no par line, exit 0; (2) with `grammar: 0.9.2` as
# the fence's first line every prose reason is an unclassed deferral: the
# commit is refused, the par line reads other=22 (11 of them carry the three
# reasons the spec names as "describes a red test", printed here as a count);
# (3) the same block with those rows cited and the legitimate deferrals
# classed passes; (4) one deploy-owed row is counted apart (deploy-owed=1,
# other=0); (5) a REQ with one passed row and one legitimately deferred row
# still fails coverage --strict with owed=1 (the accumulator unchanged);
# (6) a rule row `owed: census-armed — sites being guarded, fix F-3` is
# legal; a legal class word alone, and owner-decision without OQ-n, are not.
# Env: CHECKS (set by checks/selftest/run.sh).
set -eu
IFS='
'
FX="$CHECKS/selftest/fixtures/inventory-toy-init.md"
[ -f "$FX" ] || { echo 'inventory-par: the toy inventory fixture is missing' >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p tests/invariants/fixtures app
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
cp "$FX" INVENTORY.md
for f in $(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | grep -oE 'tests/invariants/[A-Za-z0-9_./-]+' | sort -u); do printf '# ledger — %s\n' "$f" > "$f"; done
inv() { sh "$CHECKS/inventory.sh" "$@"; }

# 1. no grammar line: today's output, pinned; no par line; the commit passes
OUT=$(inv --report)
printf '%s\n' "$OUT" | grep -qxF 'inventory: rows=26 routes=0 route-gaps=0 owed=34 deploy-owed=0 orphans=0 missing-tests=0 hostility=5 tier0=3 hostility-gaps=0' || { echo 'inventory-par: the legacy summary line changed' >&2; printf '%s\n' "$OUT" | tail -2 >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^par:' && { echo 'inventory-par: a par line printed on a legacy block' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'unclassed' && exit 1
inv >/dev/null 2>&1 || { echo 'inventory-par: the legacy block was refused' >&2; exit 1; }
[ "$(printf '%s\n' "$OUT" | grep -c '^OWED')" -eq 34 ] || exit 1

# 2. the grammar line: the deviation is refused, other=22 on the par, the 11 printed
sed '/^```vid-inventory$/a\
grammar: 0.9.2' "$FX" > INVENTORY.md
if inv >/dev/null 2>&1; then echo 'inventory-par: the legacy block passed under grammar 0.9.2' >&2; exit 1; fi
OUT=$(inv --report)
printf '%s\n' "$OUT" | grep -q '^par: rows=26 materialised=4 legitimate=0 deploy-owed=0 other=22 — FAILS' || { echo 'inventory-par: the par line is wrong' >&2; printf '%s\n' "$OUT" | grep '^par:' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'owed=34 (legitimate=0: guard-first=0 census-armed=0 probe-capture=0 golden-set=0 fixture-source=0 prerequisite=0 owner-decision=0 reverted=0; other=32)' || exit 1
[ "$(printf '%s\n' "$OUT" | grep -c 'unclassed deferral')" -eq 31 ] || exit 1      # 22 ROW + 4 rule + 5 hostility
printf '%s\n' "$OUT" | grep -q 'GAP  SEAM-002 .*credentials: not-yet born probe: owed' || exit 1
RED=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | grep -E '^ROW-' | grep -cE '\| owed: (materialised when (its|the) surface exists|browser render test lands with the screen.s slice|materialised in the slice that builds the subject)')
[ "$RED" -eq 11 ] || { echo "inventory-par: the three 'describes a red test' reasons count $RED, not 11" >&2; exit 1; }
echo "inventory-par: the legacy block under grammar 0.9.2 — par other=22; rows carrying the three red-test reasons: $RED"

# 3. the corrected block: the red-test reasons cited, the legitimate deferrals classed
sed -e 's#| owed: materialised with its guard row#| owed: guard-first — its guard row; paid in the slice that builds it#' \
    -e 's#| owed: needs the corpus fixture#| owed: fixture-source — the corpus; expected with the corpus slice#' \
    -e 's#| owed: needs the dataset fixture under tests/#| owed: fixture-source — the dataset; expected with the corpus slice#' \
    -e 's#| owed: materialised with the load fixture#| owed: fixture-source — the load fixture; expected with the volume slice#' \
    -e 's#| owed: materialised with the corpus fixture#| owed: fixture-source — the corpus; expected with the corpus slice#' \
    -e 's#| owed: golden set ratified at this sitting; test lands with the search slice#| owed: golden-set — tests/invariants/fixtures/golden_queries.txt#' \
    -e 's#| owed: armed when the first site exists#| owed: census-armed — before any site exists; armed by the first materialised site#' \
    -e 's#| owed: the protection does not exist yet; materialised and stamped by its own ritual in the slice that builds it#| owed: guard-first — its protection; paid in the slice that builds it#' \
    -e 's#| owed: materialised with the protection#| owed: guard-first — its protection; paid in the slice that builds it#' \
    -e 's#credentials: not-yet | probe: owed#credentials: not-yet | probe: unreachable-risk(credentials not-yet)#' \
    -e '/^ROW-/ s#| owed: materialised when [^|]*|#| tests/invariants/test_rows.py |#' \
    -e '/^ROW-/ s#| owed: browser render test [^|]*|#| tests/invariants/test_rows.py |#' \
    -e '/^ROW-/ s#| owed: materialised in the slice [^|]*|#| tests/invariants/test_rows.py |#' \
    -e '/^ROW-/ s#| owed: materialised with the [a-z]* slice[^|]*|#| tests/invariants/test_rows.py |#' \
    -e '/^ROW-/ s#| owed: the schedule lands [^|]*|#| tests/invariants/test_rows.py |#' \
    -e "/^ROW-/ s#| owed: the scaffold's health [^|]*|#| tests/invariants/test_rows.py |#" \
    INVENTORY.md > INV2 && mv INV2 INVENTORY.md
printf '# ledger — the rows\n' > tests/invariants/test_rows.py
OUT=$(inv --report)
printf '%s\n' "$OUT" | grep -q '^par: rows=26 materialised=19 legitimate=7 deploy-owed=0 other=0 — holds' || { echo 'inventory-par: the corrected block does not hold the par' >&2; printf '%s\n' "$OUT" | grep -E '^(par:|GAP)' | head -5 >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'guard-first=7 census-armed=4 probe-capture=0 golden-set=1 fixture-source=4 prerequisite=0 owner-decision=0 reverted=0; other=0)' || { printf '%s\n' "$OUT" | tail -2 >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^GAP' && { printf '%s\n' "$OUT" | grep '^GAP' | head -3 >&2; exit 1; }
inv >/dev/null 2>&1 || { echo 'inventory-par: the corrected block was refused' >&2; exit 1; }
if inv --strict >/dev/null 2>&1; then exit 1; fi        # legitimately deferred rows are still debt: strict blocks

# 4. one deploy-owed row is counted apart from other
sed '/^ROW-001 |/ s#| tests/invariants/test_rows.py | origin#| owed: paid by /vid deploy gate 2 — the deployed shape refuses an unconfirmed subscription | origin#' INVENTORY.md > INV2 && mv INV2 INVENTORY.md
OUT=$(inv --report)
printf '%s\n' "$OUT" | grep -q '^par: rows=26 materialised=18 legitimate=7 deploy-owed=1 other=0 — holds' || { printf '%s\n' "$OUT" | grep '^par:' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'DEPLOY-OWED  ROW-001' || exit 1
printf '%s\n' "$OUT" | grep -q ' deploy-owed=1 ' || exit 1

# 5. coverage --strict: one passed row and one legitimately deferred row on one REQ → owed=1, not done
rm -rf "$T"/*; mkdir -p checks app tests/invariants
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" checks/
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# Toy\n\n## Items\n\n```vid-prd\nREQ-001 | functional | T1 | P1 | Two promises. | fail-if: either breaks | serves: x | authority: authoritative | source: seed\n```\n' > PRD.md
printf '# Purpose: toy — REQ-001\n' > app/a.py
printf '# REQ-001 ROW-001\n' > tests/invariants/test_req001.py
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
grammar: 0.9.2
ROW-001 | behavior | REQ-001 | n/a | n/a | the first promise | REQ-001 | tests/invariants/test_req001.py
ROW-002 | behavior | REQ-001 | n/a | n/a | the second promise | REQ-001 | owed: prerequisite — a provider capture the harness lacks; paid at slice 3
```
INV
if sh checks/coverage.sh --strict >/dev/null 2>&1; then echo 'inventory-par: strict passed with a legitimately deferred row' >&2; exit 1; fi
sh checks/coverage.sh 2>&1 | grep -q 'owed=1 (legitimate=1: guard-first=0 census-armed=0 probe-capture=0 golden-set=0 fixture-source=0 prerequisite=1' || exit 1
sh checks/inventory.sh --report | grep -q '^par: rows=2 materialised=1 legitimate=1 deploy-owed=0 other=0 — holds' || exit 1

# 6. the census-armed repair form is legal; a class word alone, and owner-decision without OQ-n, are not
inv6() { { printf '# toy\n```vid-inventory\ngrammar: 0.9.2\n'; for l in "$@"; do printf '%s\n' "$l"; done; printf '```\n'; } > INVENTORY.md; }
inv6 'rule | RULE-003 | every export names its record count | printf "site-a\nsite-b\n" :: printf "site-a\n" | T1 | owed: census-armed — sites being guarded, fix F-3 | origin: REQ-001'
sh checks/inventory.sh >/dev/null 2>&1 || { echo 'inventory-par: the census-armed repair form was refused' >&2; exit 1; }
sh checks/inventory.sh --report | grep -q 'census-armed=1' || exit 1
inv6 'ROW-003 | behavior | REQ-001 | n/a | n/a | a promise | REQ-001 | owed: guard-first'
if sh checks/inventory.sh >/dev/null 2>&1; then echo 'inventory-par: a class word alone passed' >&2; exit 1; fi
inv6 'ROW-003 | behavior | REQ-001 | n/a | n/a | a promise | REQ-001 | owed: owner-decision — the owner has not said'
if sh checks/inventory.sh >/dev/null 2>&1; then echo 'inventory-par: owner-decision without OQ-n passed' >&2; exit 1; fi
inv6 'ROW-003 | behavior | REQ-001 | n/a | n/a | a promise | REQ-001 | owed: owner-decision — OQ-4'
sh checks/inventory.sh >/dev/null 2>&1 || exit 1
inv6 'ROW-003 | surface | /x | anonymous | P01/default | the page paints | REQ-001 | owed: materialised when its surface exists'
if sh checks/inventory.sh >/dev/null 2>&1; then echo 'inventory-par: "materialised when its surface exists" passed as a class' >&2; exit 1; fi
sh checks/inventory.sh --report | grep -q 'unclassed deferral' || exit 1
# a rule row with an unrecognised test field (a live project's HEAD tree shape) is a GAP and the report still reaches its summary — the 2026-09-21 replay found the court aborting here
inv6 'rule | RULE-005 | every export names its count | printf "a\n" | T1 | census: RULE-005 joined 2026-09-19 orphans=0 | origin: REQ-001' \
     'ROW-004 | behavior | REQ-001 | n/a | n/a | a promise | REQ-001 | owed: prerequisite — a capture; paid at slice 2'
OUT=$(sh checks/inventory.sh --report) || { echo 'inventory-par: --report exited non-zero on an unrecognised rule test field' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^inventory: rows=1 ' || exit 1
printf '%s\n' "$OUT" | grep -q 'unrecognized test field' || exit 1
printf '%s\n' "$OUT" | grep -q '^par: rows=1 materialised=0 legitimate=1 deploy-owed=0 other=0 — holds' || exit 1
exit 0
