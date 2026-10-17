#!/bin/sh
# Purpose: selftest case — the owner is told the run stopped for a reason
# (v0.9.5 spec 3.5, R5; §7 case 3). Convicts unless `run: stopped disk
# full` gives one notice and a second, different reason a second; `stopped
# owner asked to pause` gives none; and a stop, a resumption and the same
# stop again between two ticks (a new episode) give a second notice.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=notice-stopped
. "$CHECKS/selftest/fixtures/observer-lib.sh"
reset
rs 'stopped disk full'; ev 'run state=stopped disk full' "$(ago 60)"
tick; [ "$(nnote 'ViD: the build stopped: disk full')" -eq 1 ] || fail 'no stopped notice'
tick; [ "$(nnote 'ViD: the build stopped:')" -eq 1 ] || fail 'the stopped notice repeated'
rs 'stopped the database will not start'; ev 'run state=stopped the database will not start' "$(ago 30)"
tick; [ "$(nnote 'ViD: the build stopped: the database will not start')" -eq 1 ] || fail 'a second reason gave no notice'
reset
rs 'stopped owner asked to pause'; ev 'run state=stopped owner asked to pause' "$(ago 60)"
tick; tick; [ "$(nnote)" -eq 0 ] || fail "the owner's own pause was notified"
reset
rs 'stopped disk full'; ev 'run state=stopped disk full' "$(ago 60)"
tick; [ "$(nnote 'ViD: the build stopped: disk full')" -eq 1 ] || fail 'no stopped notice'
ev 'run state=active' "$(ago 5)"; ev 'run state=stopped disk full' "$(ago 3)"
tick; [ "$(nnote 'ViD: the build stopped: disk full')" -eq 2 ] || fail 'the same stop after a resumption gave no new notice'
exit 0
