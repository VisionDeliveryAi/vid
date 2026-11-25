#!/bin/sh
# Purpose: selftest case — the ticket of an outside service the developers can reach (`place: dev`, FB-4 A2, writer.sh), on
# TW's toy (fixtures/tw-toy.sh) with SEAM-010 in S03: its Asks hold the row's line, with no seam's probe and not among the
# deploy-owed rows; its mark is `service`; it is not among the faulted rows, though its number is a multiple of ten; SEAM-001,
# without the field, keeps its probe's line. A step of such a row alone asks the run before the code (T2). With every ticket
# published, none is due an amendment. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-place-dev: $*" >&2; cat "$T/out" "$T/werr" "$T/post" "$T/start" >&2 2>/dev/null; exit 1; }
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
L='- SEAM-010: an outside service the developers can reach: its test makes one real action through the service, with the credentials the developers have; without them its case errors with a message that begins setup:, and that is no proof.'
tw_toy "$T/toy"; W=$CHECKS/writer.sh
S='seam | SEAM-010 | the synonym service | looking up the other names of an occupation | chosen: D-003 | credentials: held | probe: owed | evidence: owed | quirks: none yet'
pt_after SEAM-002 "$S | place: dev"; pt_after SEAM-010 'seam | SEAM-020 | the address checker | checking an email address | chosen: D-003 | credentials: held | probe: owed | evidence: owed | quirks: none yet | place: dev'
pt_rs 's/\(rows: ROW-006 [^|]*HOS-005\) |/\1 SEAM-010 |/; s/^\(needs ROW-006 [^|]*HOS-005\) | -$/\1 SEAM-010 | -/'
awk '{ print } /^step S03 / { print "step S06 | name: the address checker | modules: web | builds-on: S01 | rows: SEAM-020 | lane: devagent" } /^needs ROW-006 / { print "needs SEAM-020 | -" }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x
grep -q '^step S03 .*SEAM-010' .vid/RUN-STATE.md && grep -q '^needs .*SEAM-010' .vid/RUN-STATE.md || fail 'the toy holds no SEAM-010 in S03'
printf 'open-tickets: 5\n' > "$T/s"; grep -v '^open-tickets' .vid/tw/settings > "$T/s2"; cat "$T/s2" "$T/s" > .vid/tw/settings
g add -A; g commit -qm 'two services the developers reach'; pt_record; tw_ratify 'Yes, publish it' || fail 'the plan was not ratified again'
tw_skel || fail 'the skeleton round failed'; tw_start S03 && tw_post step S03 || fail 'S03 was not posted'; F=$TW_F
sec "$F" Asks | grep -qxF -- "$L" || fail "S03's ticket does not say how SEAM-010 is tested"
! sec "$F" Asks | grep -q "SEAM-010: the seam's probe" || fail 'SEAM-010 has the probe line of a seam'
sec "$F" Asks | grep -q '^- SEAM-001: the seam.s probe' || fail 'SEAM-001 lost its probe line'
sec "$F" Asks | grep '^- Deploy-owed rows take part' > "$T/dw"; grep -q SEAM-001 "$T/dw" && ! grep -q SEAM-010 "$T/dw" || fail "the deploy-owed rows: $(cat "$T/dw")"
sec "$F" Rows | grep -qx -- '- SEAM-010 marks: service' || fail 'its mark in the ticket is not service'
sec "$F" 'Faulted rows' | grep -q . && ! sec "$F" 'Faulted rows' | grep -q 'SEAM-010' || fail 'SEAM-010 is among the faulted rows'
# a step of such a row alone: the run before the code is asked, nothing faulted
tw_start S06 && tw_post step S06 || fail 'S06 was not posted'; sec "$TW_F" Asks | grep -q '^- T2 ' || fail 'a step of a service row alone asks no T2'
! sec "$TW_F" Asks | grep -q 'Every row of this ticket is deploy-owed' || fail 'a step of a service row alone reads as deploy-owed'
sec "$TW_F" 'Faulted rows' | grep -qx none || fail 'a service row is faulted'
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'; sh "$W" due > "$T/out" 2>&1 || :; ! grep -q '^amend' "$T/out" || fail 'a published ticket is due an amendment'
exit 0
