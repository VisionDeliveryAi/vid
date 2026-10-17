#!/bin/sh
# Purpose: selftest case — what the labeller is unsure of stays visible everywhere (v0.9.7.3 spec 3.3, R3; the owner,
# 2026-10-14: no question to the owner). `decisions.sh apply` writes `scope: project` — the decision still reaches
# every builder brief, as an unlabelled one does — for a proposal marked unsure (D-002, D-003), one naming an item no
# brief joins on (D-005: P07, no row marks it), and a malformed line (D-006); a sure label to a real item is written
# as proposed (D-001 is not proposed: left alone). The record names each widened label and why; the event counts
# widened=4. A builder brief then quotes the widened lines as it quoted them unlabelled. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/labels.sh"
fail() { echo "labels-widened: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
lb_files; g add -A && g commit -qm toy; lb_hooks
lb_prop "D-002 $(lb_hash D-002) | applies-to: ROW-003 | unsure" "D-003 $(lb_hash D-003) | scope: project | unsure" \
  "D-005 $(lb_hash D-005) | applies-to: P07 | sure" "D-006 $(lb_hash D-006) applies-to: ROW-001 sure" "garbage"
sh checks/decisions.sh apply > .vid/out 2>&1 || fail 'apply was refused'
for d in D-002 D-003 D-005; do grep -q "^- \*\*$d\*\* .* | scope: project$" DECISIONS.md || fail "$d was not widened to scope: project"; done
grep -q '^- \*\*D-006\*\* .* | scope: project | origin: proposal$' DECISIONS.md || fail 'the malformed D-006 was not widened'
grep -q "^D-002	scope: project	widened: not sure (proposed applies-to: ROW-003)$" .vid/decision-labels.applied || fail 'the record does not say why D-002 was widened'
grep -q "^D-005	scope: project	widened: no brief joins on P07" .vid/decision-labels.applied || fail 'the record does not name the item no brief joins on'
grep -q "^D-006	scope: project	widened: the proposal line is malformed$" .vid/decision-labels.applied || fail 'the record does not say D-006 was malformed'
grep -q '^decision-labels applied=4 widened=4 changed=0 skipped=1 at=' .vid/metrics-events || fail 'the event does not count widened=4 and the skipped garbage line'
grep -q 'skipped: ? (a malformed line naming no decision)' .vid/out || fail 'the line naming no decision is not listed'
exit 0
