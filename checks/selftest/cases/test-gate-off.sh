#!/bin/sh
# Purpose: selftest case — outside the gate checks/test.sh is 0.9.5's, and
# the two paths never share a folder (v0.9.6 spec 3.7.6, 3.13, R7, R13; §7
# case 15). In a repository with no commit (init's red gate) and in one
# with no develop run, a scoped run takes .vid/ledger.lock (seen while it
# runs), mounts the live tree (VID_TEST_CONTEXT=.) and names its receipt
# <head>.live.sel-<hash>.xml, as fixtures/test-0.9.5.sh does. A live gated
# run folder makes an ungated run refuse; a held lock makes a gated run
# refuse. The measured kill (3.13): while a gated run is up, a rendered
# extractor that joins "a running product under the folder's default
# compose project" finds none and declares itself inactive; during an
# ungated run it would have joined. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "test-gate-off: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/rendered.sh" <<'EOF'
#!/bin/sh
# Purpose: a stub rendered extractor — joins a product running under the folder's default project
if [ -n "$($VID_COMPOSE ps -q product 2>/dev/null)" ]; then echo 'ok joined-the-running-stack'; else echo 'inactive no product running'; fi
EOF
# init's red gate: no commit yet
mkdir -p "$T/fresh/checks" "$T/fresh/app" "$T/fresh/.vid"; cd "$T/fresh"; git init -q
cp "$CHECKS/test.sh" "$CHECKS/plan.sh" checks/; printf '%s' "$COMPOSEFILE" > docker-compose.test.yml; printf 'main v1\n' > app/main.py
sh checks/test.sh -- 'tests/invariants' > "$T/out" 2>&1 || fail 'the red-gate run failed'
ls .vid/ledger-results | grep -qE '^nohead\.live\.sel-[0-9]+\.xml$' || fail 'the red-gate receipt is not named as in 0.9.5'
grep -q "^fresh||\.|tests/invariants|-f docker-compose.test.yml up " "$STUB_LOG" || fail 'the red gate did not mount the live tree'
[ -z "$(ls .vid/runs 2>/dev/null)" ] || fail 'the red gate made a run folder'
# a repository with no develop run: the lock is taken while the run holds
gated_repo "$T/repo"; rm -f "$STUB_LOG"
touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" sh checks/test.sh -- x > "$T/out" 2>&1 ) & P=$!
waitfor "$T/entered" || fail 'the ungated run never came up'
[ -d .vid/ledger.lock ] || fail 'the ungated run took no lock'
VID_COMPOSE="$T/stub.sh" sh "$T/rendered.sh" | grep -q '^ok joined' || fail 'the stub extractor does not join an ungated run (the fixture lost the 0.9.5 failure)'
rm -f "$T/hold"; wait "$P" || fail 'the ungated run failed'
grep -q '^repo||\.|x|-f docker-compose.test.yml up ' "$STUB_LOG" || fail 'the ungated run did not mount the live tree'
# a held lock refuses a gated run
gate_on
mkdir .vid/ledger.lock && printf '%s\nstarted\n%s\n' "$$" "$(date +%s)" > .vid/ledger.lock/holder
if VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- x > "$T/out" 2>&1; then fail 'a gated run started while the lock was held'; fi
grep -q 'a ledger run is in progress' "$T/out" || fail 'the gated refusal does not name the lock'
[ "$(nruns)" -eq 0 ] || fail 'the refused gated run left a run folder'
rmdir .vid/ledger.lock 2>/dev/null || rm -rf .vid/ledger.lock
# a live gated run folder refuses an ungated run; the extractor finds no stack to join
rm -f "$T/entered"; touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- x > "$T/out.g" 2>&1 ) & P=$!
waitfor "$T/entered" || fail 'the gated run never came up'
VID_COMPOSE="$T/stub.sh" sh "$T/rendered.sh" | grep -qx 'inactive no product running' || fail 'the rendered extractor joined the gated run'
sed 's/^run: .*/run: stopped owner asked to pause/' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md
if sh checks/test.sh -- y > "$T/out" 2>&1; then fail 'an ungated run started beside a live gated run'; fi
grep -q 'a gated develop run is in progress here' "$T/out" || fail 'the ungated refusal does not name the gated run'
rm -f "$T/hold"; wait "$P" || fail 'the gated run failed'
exit 0
