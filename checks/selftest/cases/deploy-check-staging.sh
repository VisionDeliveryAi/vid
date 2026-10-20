#!/bin/sh
# Purpose: selftest case — the staging check (v0.26.10.7 spec R2, R3, R5; §5 deploy-check-staging). The toy product
# (fixtures/stages.sh) without STAGES.md, so the staging candidate is HEAD. With no last full pass the check needs a
# full run of the candidate and coverage, and records `tests=full`. Then: a changed DIF row alone needs the census clean
# and no receipt (unmet once an extractor finds an orphan); a changed test (ROW-001, HOS-002 following it) needs a
# `staging` request's receipt current for the candidate — ready on one, `ahead=` the commits since the base; unmet with
# the row red, the probe red, a receipt for an older commit, or a dirty worktree; a deploy-owed row of the change set
# is listed (`owed ROW-007 gate 2`), not required. A staged toy with stage 1 closed: the candidate is vid/stage-1, ready
# from its record with an empty change set while HEAD holds later work. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "deploy-check-staging: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
dc() { sh checks/metrics.sh deploy-check --target staging "$@" > "$T/out" 2>&1; }
# srcpt <ROW-001 status> <HOS-002 status>: a staging request's receipt of HEAD, its .rows the change set, its event
srcpt() { _h=$(git rev-parse --short=12 HEAD); _n=$((${_n:-0} + 1)); _r="$_h.live.sel-$_n.xml"
  printf '<r>\n<case name="tests/invariants/test_a.py::t[ROW-001]" status="%s" time="0.1"/>\n<case name="tests/invariants/test_hos2.py::t[HOS-002]" status="%s" time="0.1"/>\n</r>\n' "$1" "$2" > ".vid/ledger-results/$_r"
  sh checks/metrics.sh change-set --base "$B1" | grep -v '^change-set ' > ".vid/ledger-results/$_r.rows"
  printf 'ledger-run seconds=3 kind=scoped report=%s status=0 role=orchestrator request=K%s type=staging rows=2 at=2026-10-20T10:00:0%sZ\n' "$_r" "$_n" "$_n" >> .vid/metrics-events; }
st_close_repo "$T/repo"
g rm -q STAGES.md; g commit -qam 'one stage: no STAGES.md'
# no last full pass: the full run and coverage
dc; grep -qx 'base: none' "$T/out" && grep -q '^unmet no full run current for ' "$T/out" && grep -q '^deploy-check staging unmet=' "$T/out" || fail 'with no last full pass and no full run it is not unmet'
st_rcpt; st_keep ROW-001 ROW-002 ROW-003 ROW-004 ROW-006
dc --record; grep -qx 'deploy-check staging ready rows=8 ahead=0' "$T/out" || fail 'the full run and clean coverage are not ready'
B1=$(git rev-parse --short=12 HEAD)
grep -q "^deploy-check target=staging sha=$B1 tests=full base=- ahead=0 rows=8 receipt=$B1.full.xml result=ready at=" .vid/metrics-events || fail 'the record does not say tests=full'
# a changed DIF row alone: the census, no receipt
awk '/^```$/ && !d { print "difference | DIF-001 | live-mail | fake | real | ratified"; d = 1 } { print }' INVENTORY.md > inv && mv inv INVENTORY.md
g commit -qam 'a ratified difference'
dc; grep -qx "base: $B1 (deploy-check target=staging tests=full)" "$T/out" || fail 'the base is not the full staging record'
grep -qx 'deploy-check staging ready rows=1 ahead=1' "$T/out" || fail 'a changed DIF row with the census clean is not ready without a receipt'
printf '#!/bin/sh\n# Purpose: a toy extractor finding one orphan\necho "orphan app/main.py unguarded"\n' > checks/extractors/divergence.toy.sh; g add -A; g commit -qm 'an orphan'
dc; grep -q '^unmet census: not clean' "$T/out" || fail 'a changed DIF row with the census not clean is not unmet'
g rm -q checks/extractors/divergence.toy.sh; g commit -qm 'no orphan'
# a changed test: a staging receipt
printf '# changed\n' >> tests/invariants/test_a.py; g commit -qam 'ROW-001 test changed'
dc; grep -q '^unmet no staging receipt current for ' "$T/out" || fail 'a changed row with no staging receipt is not unmet'
srcpt passed passed
dc --record; grep -qx 'deploy-check staging ready rows=3 ahead=4' "$T/out" || fail 'the change set passing in a staging receipt is not ready with ahead=4'
grep -q "^deploy-check target=staging sha=$(git rev-parse --short=12 HEAD) tests=scoped base=$B1 ahead=4 rows=3 receipt=.*live.sel-1.xml result=ready" .vid/metrics-events || fail 'the scoped record is not written'
srcpt failed passed; dc; grep -q '^unmet ROW-001: not green' "$T/out" || fail 'a red changed row is not unmet'
srcpt passed failed; dc; grep -q '^unmet HOS-002: not green' "$T/out" || fail 'a red probe is not unmet'
srcpt passed passed
printf '# a code change\n' >> app/main.py; g commit -qam 'code after the receipt'
dc; grep -q '^unmet no staging receipt current for ' "$T/out" || fail 'a receipt for an older commit counted'
srcpt passed passed; dc; grep -q '^deploy-check staging ready rows=3 ahead=5' "$T/out" || fail 'not ready again on a current receipt'
printf '# dirty\n' >> app/main.py
dc; grep -q '^unmet .*uncommitted changes' "$T/out" || fail 'a dirty worktree is not unmet'
g checkout -q -- app/main.py
# a deploy-owed row of the change set: listed, not required
awk '/^```$/ && !d { print "ROW-007 | behavior | REQ-002 | anonymous | n/a | a note reaches the mailbox | REQ-002 | owed: paid by /vid deploy gate 2 — one real mail"; d = 1 } { print }' INVENTORY.md > inv && mv inv INVENTORY.md
g commit -qam 'a row born owed to gate 2'; srcpt passed passed
dc; grep -qx 'owed ROW-007 gate 2' "$T/out" && grep -q '^deploy-check staging ready rows=4 ' "$T/out" || fail 'the deploy-owed row is not listed, or it is required'
# a staged toy, stage 1 closed: the tag, ready from its record, while HEAD holds later work
st_close_repo "$T/staged"
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || fail 'the close was not recorded'
TAGC=$(git rev-parse --short=12 "vid/stage-1^{commit}")
printf '# stage 2 work\n' >> app/main.py; printf '# changed\n' >> tests/invariants/test_a.py; g commit -qam 'stage 2 work'
dc; grep -qx "base: $TAGC (stage-closed n=1)" "$T/out" && grep -qx 'deploy-check staging ready rows=0 ahead=0' "$T/out" || fail 'the stage tag is not ready from its record with an empty change set'
exit 0
