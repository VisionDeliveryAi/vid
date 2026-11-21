#!/bin/sh
# Purpose: selftest case — one reader of what the team has, in both modes (GM-4 F8, its case applied-reader). On the GitHub manual
# toy (fixtures/manual.sh), HEAD moved past the spec's commit AP: in GitHub auto lib.sh's `applied` prints HEAD, with no
# .vid/tw/applied and with a stale one left there alike; in GitHub manual it prints the record's first line, AP, and nothing
# when no record is kept; /vid mode's own mark (VID_CALLER=mode) reads the record in auto, and its switch to auto
# (VID_CALLER=mode-auto) reads HEAD in manual. No script of checks/ but lib.sh reads .vid/tw/applied itself: every reader asks
# `applied` (the writes of the record, by /vid mode and the apply, and the apply's backups of it stand). Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "applied-reader: $*" >&2; exit 1; }
ap() { sh -c '. "$1/lib.sh"; applied' x "$CHECKS"; }
mn_project "$T/p"
echo 'a later line' >> PRD.md; git commit -qam 'a change after the spec'; HD=$(git rev-parse HEAD)
[ "$HD" != "$AP" ] || fail 'the toy did not move HEAD'
printf 'setup-answered key=github-mode value="auto" words="DevAgent works them" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
[ "$(ap)" = "$HD" ] || fail "in GitHub auto with no record, applied printed '$(ap)', not HEAD"
echo "$AP" > .vid/tw/applied
[ "$(ap)" = "$HD" ] || fail "in GitHub auto a record left behind was read: applied printed '$(ap)', not HEAD"
[ "$(VID_CALLER=mode ap)" = "$AP" ] || fail "under /vid mode's mark in auto, applied did not read the record"
printf 'setup-answered key=github-mode value="manual" words="by hand" at=2026-11-03T10:00:00Z\n' >> .vid/plan/setup
[ "$(ap)" = "$AP" ] || fail "in GitHub manual applied printed '$(ap)', not the record's commit"
[ "$(VID_CALLER=mode-auto ap)" = "$HD" ] || fail "under the switch to auto's mark in manual, applied did not read HEAD"
rm -f .vid/tw/applied; [ -z "$(ap)" ] || fail "in GitHub manual with no record, applied printed '$(ap)'"
# no script but lib.sh reads the record itself
grep -nE '(^|[^A-Za-z_])(sed|cat|head|tail|awk|grep|cut|cmp) [^|;]*\.vid/tw/applied([^.a-z_]|$)|<[[:space:]]*"?[^ ]*\.vid/tw/applied([^.a-z_]|$)' "$CHECKS"/*.sh "$CHECKS"/lib/*.sh 2>/dev/null |
  grep -v '^[^:]*:[0-9]*:[[:space:]]*#' | grep -v '/lib\.sh:' > "$T/rd" || :
[ ! -s "$T/rd" ] || { cat "$T/rd" >&2; fail 'a script reads .vid/tw/applied itself, not through lib.sh applied (above)'; }
echo 'applied-reader: ok'
