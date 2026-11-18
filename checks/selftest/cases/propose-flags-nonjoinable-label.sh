#!/bin/sh
# Purpose: selftest case — the labelling pass agrees with the commit hook (0.26.10.29.3, R7, F32). On the labelling toy
# (fixtures/labels.sh) with every committed line labelled, two new lines carry labels the hook refuses: D-007's names
# REQ-777, which no row derives from, and D-008 carries two labels. `decisions.sh propose` (and `--all`) lists both,
# never "no decision to label"; `apply` replaces each label, keeping the text-hash check, so each line ends with one
# joinable label and its commit passes the real hooks; D-004, labelled scope: project, is still skipped as already
# labelled. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/labels.sh"
fail() { echo "propose-flags-nonjoinable-label: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
lb_files
sed 's/enforced: convention$/enforced: convention | scope: project/; s#test_gone.py$#test_gone.py | scope: project#; s/| origin: proposal$/| scope: project | origin: proposal/' DECISIONS.md > x && mv x DECISIONS.md
g add -A && g commit -qm toy; lb_hooks
D7='- **D-007** receipts are kept | why: audit | enforced: convention'
D8='- **D-008** one currency | why: scope | enforced: convention'
printf '%s | applies-to: REQ-777\n%s | applies-to: ROW-001 | scope: project\n' "$D7" "$D8" >> DECISIONS.md
uh() { printf '%s\n' "$1" | git hash-object --stdin | cut -c1-12; }
sh checks/decisions.sh propose > .vid/out 2>&1 || fail 'propose failed'
grep -q '^propose: no decision to label$' .vid/out && fail 'propose found no decision to label while the hook would refuse two'
grep -q '^propose: 2 decisions → .vid/briefs/labels-1.md$' .vid/out || fail 'propose did not list the two lines the hook refuses'
grep -q "^D-007 $(uh "$D7") | " .vid/briefs/labels-1.md && grep -q "^D-008 $(uh "$D8") | " .vid/briefs/labels-1.md || fail 'D-007 and D-008 are not listed with their text hashes'
sh checks/decisions.sh propose --all > .vid/out 2>&1; grep -q '^propose: 2 decisions → .vid/briefs/labels-2.md$' .vid/out || fail '--all did not list the two lines'
lb_prop "D-007 $(uh "$D7") | applies-to: ROW-002 | sure" "D-008 $(uh "$D8") | applies-to: ROW-001 | sure" "D-004 $(uh '- **D-004** logs kept a year | why: audit | enforced: convention') | applies-to: ROW-003 | sure"
H0=$(git rev-parse HEAD)
sh checks/decisions.sh apply > .vid/out 2>&1 || fail 'apply was refused (its commit through the hooks)'
grep -qxF -- "$D7 | applies-to: ROW-002" DECISIONS.md || fail 'D-007 does not carry its one new label'
grep -qxF -- "$D8 | applies-to: ROW-001" DECISIONS.md || fail 'D-008 does not carry one label'
grep -qxF -- '- **D-004** logs kept a year | why: audit | enforced: convention | scope: project' DECISIONS.md || fail 'D-004, already joinable, was relabelled'
grep -q 'D-004 (already labelled)' .vid/out || fail 'D-004 is not skipped as already labelled'
[ "$(git rev-list --count "$H0..HEAD")" = 1 ] || fail 'the labels were not committed'
git status --porcelain DECISIONS.md | grep -q . && fail 'DECISIONS.md is left uncommitted'
sh checks/decisions.sh propose > .vid/out 2>&1; grep -q '^propose: no decision to label$' .vid/out || fail 'a second pass still found something to label'
echo 'propose-flags-nonjoinable-label: ok'
