#!/bin/sh
# Purpose: selftest case — the builder's brief, its sections from HEAD (v0.9.7.0.7 spec 3.2, R3;
# §6 B-1). The brief-write fixture with bw_builder. Convicts unless `sh checks/brief.sh write --role
# builder`: refuses a builder brief without --step, writing nothing; writes .vid/briefs/<N>/builder-1.md
# whose header names the step and `skill: vid-build`, with sections 1–3 and 5–12 and the check's ok;
# section 10 quotes `plan: <hash>`, the step's line and its builds-on step's line from the kept
# plan, and the module-table rows whose Module column is one of the step's modules (`app`,
# `tests.invariants` for `tests/invariants/`) and not `app/other`; section 11 the rule rows whose
# origin: cites REQ-004, not REQ-0041's or the one citing nothing; section 12 the --notes file
# verbatim; section 8 names the harness and canvases; and a fixer brief's header gains `skill:
# vid-build` (otherwise unchanged: no section 9). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-builder-sections: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
if bw_write --role builder --slice 2 --rows ROW-104; then fail 'a builder brief without --step was written'; fi
grep -qF 'a builder brief names its plan step (--step)' "$T/wout" || fail 'the refusal does not name --step'
[ ! -d .vid/briefs/2 ] || [ -z "$(ls .vid/briefs/2)" ] || fail 'a refused brief left a file'
printf 'Continue from branch b1 at abc123; its return is .vid/briefs/2/builder-0.return.md.\n' > "$T/notes.txt"
bw_write --role builder --slice 2 --step S2 --rows ROW-104,ROW-120,ROW-105 --notes "$T/notes.txt" || fail 'the writer refused a well-formed builder brief'
B=$(bw_out); [ "$B" = .vid/briefs/2/builder-1.md ] || fail "the brief is not builder-1.md: $B"
grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok'
sed -n 1p "$B" | grep -qx 'role: builder    slice: 2    step: S2' || fail 'the header does not name the step'
grep -qx 'skill: vid-build' "$B" || fail 'the header lacks skill: vid-build'
grep -qx 'receives: 1–3, 5–12    must not receive: another batch'"'"'s brief or verdicts' "$B" || fail 'the header does not quote the role table'
for n in 1 2 3 5 6 7 8 9 10 11 12; do grep -qE "^## $n( |\$)" "$B" || fail "no section $n"; done
sec() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$B"; }
sec 10 | grep -qx 'plan: 0123456789ab' || fail 'section 10 does not name the plan'
sec 10 | grep -qxF "$(grep '^step S2 ' .vid/plans/0123456789ab.plan)" || fail "section 10 lacks the step's line"
sec 10 | grep -qxF "$(grep '^step S1 ' .vid/plans/0123456789ab.plan)" || fail "section 10 lacks the builds-on step's line"
sec 10 | grep -qxF '| app | the link store: create, resolve, expire, delete | one file per link | `app/links.sh` — link_create, link_resolve, link_delete | tests/invariants |' || fail 'section 10 lacks the app module row'
sec 10 | grep -qxF '| tests.invariants | the ledger | none | none | - |' || fail 'section 10 lacks tests.invariants (normalised from tests/invariants/)'
sec 10 | grep -q 'app/other' && fail 'section 10 carries a module the step does not name'
sec 11 | grep -q 'RULE-001' || fail 'section 11 lacks the rule citing REQ-004'
sec 11 | grep -q 'RULE-002\|RULE-003' && fail 'section 11 carries a rule whose origin is not an item (REQ-0041) or is empty'
sec 12 | grep -qxF "$(cat "$T/notes.txt")" || fail 'section 12 is not the notes file verbatim'
sec 8 | grep -qx 'the harness:' && sec 8 | grep -qx 'the canvases:' || fail 'section 8 does not name the harness and the canvases'
bw_write --role fixer --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused a fixer brief'
F=$(bw_out); grep -qx 'skill: vid-build' "$F" || fail 'the fixer brief lacks skill: vid-build'
grep -q '^## 9' "$F" && fail 'the fixer brief gained section 9'
grep -q '^## 4' "$F" || fail 'the fixer brief lost its laws'
exit 0
