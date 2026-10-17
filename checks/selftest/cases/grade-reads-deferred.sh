#!/bin/sh
# Purpose: selftest case — the end grade reads the deferrals (v0.9.7.2 spec 3.7, R11). Where ViD's skills sit beside
# checks/: vid-grade reads the `deferred` events (open: no later deferred-resolved) and .vid/end-grade-queue.md when
# it exists; vid-develop, under breadth first, records a deferral with `metrics.sh defer` instead of writing that file;
# vid-fix records `defer-resolved` for a deferred row it fixes. In a project the case proves nothing. Env: CHECKS.
set -eu
fail() { echo "grade-reads-deferred: $*" >&2; exit 1; }
SK="$CHECKS/../skills"
[ -f "$SK/vid-grade/SKILL.md" ] || exit 0
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
flat "$SK/vid-grade/SKILL.md" | grep -qF 'reads the open deferrals — each `deferred` event with no later `deferred-resolved` for its row' || fail 'vid-grade does not read the deferred events'
flat "$SK/vid-grade/SKILL.md" | grep -qF '.vid/end-grade-queue.md' || fail 'vid-grade no longer reads the end-grade file'
flat "$SK/vid-develop/SKILL.md" | grep -qF 'sh checks/metrics.sh defer --kind' || fail 'vid-develop does not record deferrals'
flat "$SK/vid-develop/SKILL.md" | grep -qF 'Under breadth first develop never writes `.vid/end-grade-queue.md`' || fail 'vid-develop still writes the end-grade file under breadth first'
flat "$SK/vid-fix/SKILL.md" | grep -qF 'sh checks/metrics.sh defer-resolved --row' || fail 'vid-fix does not resolve a deferral it fixes'
exit 0
