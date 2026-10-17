#!/bin/sh
# Purpose: selftest case — the record contradicted by the work (v0.9.5 spec
# 3.5, R5; §7 case 6). Convicts unless a quiet `waiting` with no `Q<n>`
# line — a session line newer than its `run state` event, then nothing for
# an interval — gets the quiet notice and not this one; a `waiting` with a `Q1`
# whose `run state` event is older than a new commit gives one "working
# while its record says" notice; and so does a `stopped` with a newer
# commit. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=notice-contradicted
. "$CHECKS/selftest/fixtures/observer-lib.sh"
reset; rs waiting; ev 'run state=waiting' "$(ago 600)"; hb "$(ago 300)" 'a line after the waiting, itself quiet since'
tick; [ "$(nnote 'gone quiet')" -eq 1 ] && [ "$(nnote 'working while')" -eq 0 ] || fail 'a quiet waiting with no question'
reset
rs waiting "- Q1 · asked $(ago 700) · gates all remaining work · Is the export weekly?"; ev 'run state=waiting' "$(ago 600)"
printf 'x\n' >> w.txt; g add w.txt; g commit -qm 'work after the waiting was recorded'
tick; [ "$(nnote 'ViD: the build is working while its record says waiting')" -eq 1 ] || fail 'a waiting contradicted by a commit'
tick; [ "$(nnote 'working while')" -eq 1 ] || fail 'the contradiction repeated'
reset; rs 'stopped disk full'; ev 'run state=stopped disk full' "$(ago 600)"
printf 'y\n' >> w.txt; g add w.txt; g commit -qm 'work after the stop'
tick; [ "$(nnote 'ViD: the build is working while its record says stopped disk full')" -eq 1 ] || fail 'a stopped contradicted by a commit'
exit 0
