#!/bin/sh
# Purpose: selftest case — the dev side's decisions recorded at a merge (0.26.10.29.5, DP-1 R2). A merged pull request of ticket 3
# whose description's Decisions section holds two lines: `decisions.sh record` appends both to DECISIONS.md, numbered from
# `decisions.sh next` (D-002, D-003), each `| enforced: ticket 3 | <label> | origin: dev-side`, a `|` in the dev side's words written
# `/`, a missing why `not given`; the first labelled with the ticket's ROW and RULE ids and its step's modules, normalised and kept
# only where the label hook joins (SEAM-001, HOS-001, ROW-009 and app/gone left out), the second, ending `| scope: project`,
# labelled so. One commit of DECISIONS.md alone through both hooks, its Decisions: line naming both; one event
# `decisions-recorded pr=5 n=2`; the spec repository exported at once. Run again: nothing more is read, written or recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-record-two: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD)
dpr_pr 5 3 'ticket: #3

What the branch does.

Decisions:
- pages hold 20 items | why: the list | the grid both fit
- the session cookie is signed with HMAC-SHA256 (RFC 2104) | scope: project

More words.'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qxF -- '- **D-002** pages hold 20 items | why: the list / the grid both fit | enforced: ticket 3 | applies-to: ROW-001, RULE-001, app/login, app/notes | origin: dev-side' DECISIONS.md || fail "the first line is not recorded as it should be: $(grep 'D-002' DECISIONS.md || echo none)"
grep -qxF -- '- **D-003** the session cookie is signed with HMAC-SHA256 (RFC 2104) | why: not given | enforced: ticket 3 | scope: project | origin: dev-side' DECISIONS.md || fail "the second line is not recorded as it should be: $(grep 'D-003' DECISIONS.md || echo none)"
[ "$(git rev-list --count "$H0..HEAD")" = 1 ] || fail 'not one commit'
[ "$(git diff --name-only "$H0" HEAD)" = DECISIONS.md ] || fail 'the commit holds more than DECISIONS.md'
git status --porcelain DECISIONS.md | grep -q . && fail 'DECISIONS.md is left uncommitted'
git log -1 --format=%B | grep -q '^Decisions: .*D-002.*D-003' || fail "the commit's Decisions: line does not name both: $(git log -1 --format=%B)"
[ "$(grep -c '^decisions-recorded pr=5 n=2 at=' .vid/metrics-events)" = 1 ] || fail 'not one event decisions-recorded pr=5 n=2'
[ "$(dpr_spec)" = "$(git show HEAD:DECISIONS.md)" ] || fail 'the spec repository was not exported at once'
H1=$(git rev-parse HEAD); dpr_rec; [ "$RC" = 0 ] || fail "a second record exited $RC"
[ "$(git rev-parse HEAD)" = "$H1" ] || fail 'a second record committed again'
[ "$(grep -c '^- \*\*D-0' DECISIONS.md)" = 3 ] || fail 'a line was recorded twice'
[ "$(grep -c '^decisions-recorded pr=5 ' .vid/metrics-events)" = 1 ] || fail 'the merge was recorded again'
[ "$(dpr_reads 5)" = 1 ] || fail "the description was read again: $(dpr_reads 5) reads"
exit 0
