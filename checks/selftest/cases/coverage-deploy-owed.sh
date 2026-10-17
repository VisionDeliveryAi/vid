#!/bin/sh
# Purpose: selftest case — the phase-aware denominators (v0.9.1 spec 3.6,
# R12-i, R13). In a toy project: coverage.sh --strict passes with one
# deploy-owed row (a pilot REQ whose only inventory row is `owed: paid by
# /vid deploy gate 2 — …`, no source citation, no ledger test) and prints
# it; fails when that row is an ordinary owed row; passes with a `later`
# Tier-0 item that has a drawn screen and no code, no test and no hostility
# sibling (all three denominators exclude it; the item and the marker are
# listed as deferred), and the same manifest passes design-join.sh with its
# `later:` row counted as resolved; fails when that item is `pilot`.
# Env: CHECKS (set by checks/selftest/run.sh).
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks app tests/invariants design/screens
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" "$CHECKS/design-join.sh" "$CHECKS/design-cite.sh" checks/
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
cat > PRD.md <<'PRD'
# Toy — PRD
grammar: 0.9.1

## Items

```vid-prd
REQ-001 | functional | T1 | A visitor sees the home page. | fail-if: the home page does not render | serves: the door | authority: authoritative | source: seed | phase: pilot
REQ-002 | functional | T1 | The nightly digest is sent by the deployed worker. | fail-if: a scheduled digest is never sent in production | serves: the alert channel | authority: authoritative | source: seed | phase: pilot
REQ-003 | functional | T0 | A subscriber exports every record held about them. | fail-if: an export omits a held record | serves: the right to a copy | authority: authoritative | source: seed | phase: later
```
PRD
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
ROW-001 | surface | / | anonymous | n/a | the home page renders | REQ-001 | tests/invariants/test_home.py
ROW-002 | behavior | REQ-002 | n/a | n/a | the deployed worker consumes the digest schedule and a digest is delivered | REQ-002 | owed: paid by /vid deploy gate 2 — a scheduled digest arrives at the owner's address from staging
```
INV
printf '# Purpose: toy home — REQ-001\n' > app/home.py
printf '# REQ-001 ROW-001\n' > tests/invariants/test_home.py
printf '<!-- @screen P09 state=default reqs=REQ-003 -->\n<section>{{ export }}</section>\n' > design/screens/p09.html
printf '# brief\n```vid-design-manifest\nP09 | default | REQ-003 | later: REQ-003 is a later item\n```\n' > DESIGN-BRIEF.md
sh checks/design-join.sh DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || { echo 'coverage-deploy-owed: the later: manifest row is not counted resolved (R13)' >&2; exit 1; }
OUT=$(sh checks/coverage.sh --strict 2>&1) || { echo 'coverage-deploy-owed: --strict failed on the deploy-owed toy:' >&2; printf '%s\n' "$OUT" | tail -6 >&2; exit 1; }
printf '%s\n' "$OUT" | grep -qE '^REQ-002 .*DEPLOY-OWED \(ROW-002\)' || exit 1          # the pilot REQ with only deploy-owed rows, named
printf '%s\n' "$OUT" | grep -q 'later (deferred, never a gap): REQ-003' || exit 1
printf '%s\n' "$OUT" | grep -q 'deploy-owed: 1   later items: 1   later markers: 1' || exit 1
printf '%s\n' "$OUT" | grep -q 'deploy-owed=1' || exit 1                                    # the inventory summary counts it apart from owed
printf '%s\n' "$OUT" | grep -q 'DEPLOY-OWED  ROW-002' || exit 1                            # the row is present and named, never silently absent
printf '%s\n' "$OUT" | grep -E '^REQ-003 ' | grep -q GAP && exit 1                       # the later item is no gap
# an ordinary owed row on the same REQ is a gap
sed 's#owed: paid by /vid deploy gate 2 — a scheduled digest arrives at the owner.s address from staging#owed: scaffold#' INVENTORY.md > INV2 && mv INV2 INVENTORY.md
if sh checks/coverage.sh --strict >/dev/null 2>&1; then echo 'coverage-deploy-owed: an ordinary owed row passed --strict' >&2; exit 1; fi
sed 's#owed: scaffold#owed: paid by /vid deploy gate 2 — a scheduled digest arrives at the owner'"'"'s address from staging#' INVENTORY.md > INV2 && mv INV2 INVENTORY.md
sh checks/coverage.sh --strict >/dev/null 2>&1 || exit 1
# the later T0 item made pilot: no code, no test, no sibling — a gap on every denominator
sed 's/phase: later/phase: pilot/' PRD.md > PRD2 && mv PRD2 PRD.md
if sh checks/coverage.sh --strict >/dev/null 2>&1; then echo 'coverage-deploy-owed: a pilot T0 item with nothing behind it passed --strict' >&2; exit 1; fi
sh checks/coverage.sh 2>&1 | grep -qE '^REQ-003 .*GAP' || exit 1
sh checks/inventory.sh --report 2>&1 | grep -q 'OWED  REQ-003 (Tier-0 item)' || exit 1
exit 0
