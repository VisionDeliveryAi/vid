#!/bin/sh
# Purpose: selftest case — section 10 quotes the modules the step may call (v0.9.7.1 spec 3.2d, R2). The
# brief-write fixture with bw_builder, plus ARCHITECTURE rows `lib` (Dependents: app), `core` (all) and `far`
# (other). Convicts unless a builder brief for S1 (modules app/) quotes the app row, then lib's and core's, and
# not far's; and the check says ok. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-called-modules: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
printf '| lib | shared helpers | none | `lib/x.sh` — x | app |\n| core | the core | none | `core/c.sh` — c | all |\n| far | far away | none | `far/f.sh` — f | other |\n' >> ARCHITECTURE.md
g add -A && g commit -qm calls
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'the builder brief was refused'
B=$(bw_out); grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok'
sec() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$B"; }
sec 10 | grep -qF '| app | the link store' || fail 'section 10 lost the step'"'"'s own module'
sec 10 | grep -qxF '| lib | shared helpers | none | `lib/x.sh` — x | app |' || fail 'section 10 lacks lib, whose Dependents name app'
sec 10 | grep -qxF '| core | the core | none | `core/c.sh` — c | all |' || fail 'section 10 lacks core (all)'
sec 10 | grep -q '| far |' && fail 'section 10 carries a module the step may not call'
[ "$(sec 10 | grep -n '^| app |' | cut -d: -f1)" -lt "$(sec 10 | grep -n '| lib |' | cut -d: -f1)" ] || fail 'the called modules come before the step'"'"'s own'
exit 0
