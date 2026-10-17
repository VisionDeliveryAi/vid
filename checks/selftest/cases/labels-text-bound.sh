#!/bin/sh
# Purpose: selftest case — a label applies only to the text it was proposed for (v0.9.7.3 spec 3.3, R3). After the
# proposals, D-003's text changes (a commit made before labels were required); `decisions.sh apply` labels the others,
# leaves D-003 unlabelled and lists it as changed, records changed=1, and a line that equals its proposal apart from
# a label field is not "changed". Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/labels.sh"
fail() { echo "labels-text-bound: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
lb_files; g add -A && g commit -qm toy; lb_hooks
lb_prop "D-002 $(lb_hash D-002) | applies-to: RULE-001 | sure" "D-003 $(lb_hash D-003) | scope: project | sure" "D-005 $(lb_hash D-005) | applies-to: ROW-002 | sure"
sed 's/one font everywhere/two fonts at most/' DECISIONS.md > x && mv x DECISIONS.md; g commit -qam 'D-003 reworded' --no-verify
sh checks/decisions.sh apply > .vid/out 2>&1 || fail 'apply was refused'
grep -q '^apply: 1 changed since their proposal, not labelled: D-003$' .vid/out || fail 'the changed decision is not listed'
grep -qxF -- '- **D-003** two fonts at most | why: brand | enforced: convention' DECISIONS.md || fail 'the changed D-003 was labelled'
grep -q '^- \*\*D-002\*\* .* | applies-to: RULE-001$' DECISIONS.md && grep -q '^- \*\*D-005\*\* .* | applies-to: ROW-002$' DECISIONS.md || fail 'the unchanged decisions were not labelled'
grep -q '^decision-labels applied=2 widened=0 changed=1 skipped=0 at=' .vid/metrics-events || fail 'changed=1 not recorded'
exit 0
