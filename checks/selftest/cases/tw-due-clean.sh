#!/bin/sh
# Purpose: selftest case — each rewrite starts clean (v0.26.10.12.3.2 R3). On TW's toy a step
# S06 takes DIF-002 and SEAM-002, rows citing no item, from S02, whose rows cite REQ-001 among others; the change is
# recorded, which keeps the ratification. With S02's ticket (#2) and S06's (#3) both open, `writer.sh due` re-writes the
# two in one shell and owes nothing: #3's rewrite is the ticket as published, which cites no rule. Before R3 it owed
# `amend 3`: #2's items stayed in the writer's list, so #3 gained the rules that bear on them. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-due-clean: $*" >&2; cat "$T/out" "$T/werr" "$T/start" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
pt_rs 's/^\(step S02 .*\)SEAM-002 DIF-002 /\1/'
pt_after 'step S03' 'step S06 | name: the first feed and the worker | modules: ingest | builds-on: S01 | rows: SEAM-002 DIF-002 | lane: devagent'
sh "$CHECKS/plan.sh" change split 'S06 takes the first feed and the worker' --trigger initial --expect 'S02 and S06 go side by side' > "$T/out" 2>&1 || fail 'the plan change was refused'
tw_skel || fail 'the skeleton round failed'
tw_start S02 && tw_post step S02 || fail "S02's ticket failed"
tw_start S06 && tw_post step S06 || fail "S06's ticket failed"
[ "$TW_N" = 3 ] || fail "S06's ticket is #$TW_N"
F=$TW_F; sed -n '/^## Rules that bear on these rows$/,/^## /p' "$F" | grep -qx 'none' || fail "S06's ticket, as written alone, cites a rule"
sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1
sh "$W" due > "$T/due" 2> "$T/werr" || fail 'due failed'
[ ! -s "$T/due" ] || fail "due owes something right after both were published: $(paste -sd ';' "$T/due")"
exit 0
