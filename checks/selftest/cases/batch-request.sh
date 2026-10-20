#!/bin/sh
# Purpose: selftest case — a close batch is asked and runs from one export (v0.9.7.0.12 spec 3.2,
# R2; §6 B). Refused at the request, leaving no ticket: --batch without both phase files, with a
# selection of its own, on an iterate; a group line that does not parse; a row in two groups;
# deployed words under a harness with no deployed-selector:. A lawful batch's ticket records
# batch=yes and its groups; at serve it exports HEAD's tree once (.vid/requests/<ticket>/export,
# every chunk's test context, removed at its end): a commit at the home while the first chunks run
# changes nothing — every chunk, the later phase's too, tests the frozen tree's file and names the
# frozen commit — and the batch ends green. Groups that leave out a required row are refused at
# serve: `refused:`, the row named, failed-to-start, exit 2, no chunk. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-request: $*" >&2; cat "$T/req" "$T/wait" >&2 2>/dev/null; exit 1; }
batch_repo "$T/repo"
groups "$T/p1" 3 4; groups "$T/p2" 1 2
nt() { ls .vid/requests 2>/dev/null | grep -c . || true; }
# refusals before a ticket
if sh checks/test.sh request --type close --role orchestrator --steps S2 --batch --phase1 "$T/p1" --why x > "$T/req" 2>&1; then fail 'a batch without --phase2 was accepted'; fi
grep -q 'names both phase files' "$T/req" || fail 'the missing phase file is not named'
if batch -- tests/invariants; then fail 'a batch with its own selection was accepted'; fi
grep -q 'no -- <selection>' "$T/req" || fail 'the selection refusal does not say why'
if sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-003 --batch --why x -- t > "$T/req" 2>&1; then fail '--batch on an iterate was accepted'; fi
printf 'ROW-003 %s\n' "$(w 2 3)" > "$T/bad"; cp "$T/bad" "$T/p1"
if batch; then fail 'a group line with no | was accepted'; fi
grep -q 'do not parse' "$T/req" && grep -q 'phase 1 line 1' "$T/req" || fail 'the unparsed line is not named'
printf 'ROW-003 | %s |\nROW-003,ROW-004 | %s |\n' "$(w 2 3)" "$(w 2 4)" > "$T/p1"
if batch; then fail 'a row in two groups was accepted'; fi
grep -q 'one group only: ROW-003' "$T/req" || fail 'the row in two groups is not named'
printf 'ROW-003 | %s | dep-word\nROW-004 | %s |\n' "$(w 2 3)" "$(w 2 4)" > "$T/p1"
if batch; then fail 'deployed words without deployed-selector: were accepted'; fi
grep -q 'no deployed-selector:' "$T/req" || fail 'the deployed words refusal does not say why'
[ "$(nt)" -eq 0 ] || fail 'a refused batch left a ticket'
# a lawful batch, a commit while its first chunks run
groups "$T/p1" 3 4; touch "$T/hold"
STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" batch || fail 'a lawful batch was refused'
TD=.vid/requests/$TK
grep -qx 'batch=yes' "$TD/request" && [ "$(grep -c . "$TD/groups")" -eq 4 ] || fail 'the ticket does not record the batch and its groups'
waitfor "$T/entered" 30 || fail 'no chunk reached its up'
[ -d "$TD/export" ] && [ -f "$TD/export/app/main.py" ] || fail 'no export at the ticket'
H0=$(sed -n 's/^base=//p' "$TD/batch"); T0=$(sed -n 's/^tree=//p' "$TD/batch")
[ "$H0" = "$(git rev-parse --short=12 HEAD)" ] || fail 'the batch did not freeze HEAD'
printf 'main v2\n' > app/main.py; commit_all 'a builder commits meanwhile'
rm -f "$T/hold"
bwait || fail "the batch did not end green: $(cat "$TD/result" 2>/dev/null)"
head -n 1 "$TD/result" | grep -qx green || fail 'the result is not green'
[ "$(grep -c '^ctx-main=' "$STUB_LOG")" -eq 4 ] || fail 'not four chunk runs'
grep '^ctx-main=' "$STUB_LOG" | grep -v 'main v1' && fail 'a chunk tested the tree committed after the freeze'
awk -F'|' 'NF >= 5 && $5 ~ / up / { print $3 }' "$STUB_LOG" | sort -u > "$T/ctx"
[ "$(grep -c . "$T/ctx")" -eq 1 ] && grep -q "/.vid/requests/$TK/export$" "$T/ctx" || fail "the chunks did not all run the one export: $(cat "$T/ctx")"
[ ! -d "$TD/export" ] || fail 'the export was kept after the batch'
for r in $(kept | grep '\.close\.xml$'); do
  case "$r" in "$H0".run-*) ;; *) fail "a chunk receipt names another commit: $r" ;; esac
  grep -qx "tree=$T0" ".vid/ledger-results/$r.tree" || fail "a chunk receipt names another tree: $r"
done
# groups that leave out a required row: refused at serve
groups "$T/p2" 1
batch || fail 'the request was refused before serve'
TD=.vid/requests/$TK
if bwait; then fail 'groups without a required row ran'; fi
grep -q '^refused: the groups do not hold' "$TD/result" && grep -q 'required rows in no group: ROW-002' "$TD/result" || fail "the serve refusal: $(cat "$TD/result")"
[ "$(cat "$TD/state")" = failed-to-start ] && [ "$(cat "$TD/exit")" = 2 ] || fail 'the refused batch is not failed-to-start, exit 2'
[ ! -d "$TD/chunks" ] || fail 'a refused batch made chunks'
exit 0
