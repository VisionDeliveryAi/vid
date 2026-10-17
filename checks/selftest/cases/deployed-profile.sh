#!/bin/sh
# Purpose: selftest case — the close run in the deployed shape (v0.9.3 spec
# 3.3, R4; §7 case 12, the recording-stub half; the real-container half is
# the fixture procedure checks/selftest/fixtures/deployed-profile/run-real.sh,
# run outside the suite because the suite needs no container engine). A toy
# repository whose harness contract declares a deployed selector, two
# processes and a transport. Convicts unless: a full run makes the stub see,
# in order, the inline `up … tests`, a `down --remove-orphans --volumes`,
# `up -d --build product <profile services>` with the profile, VID_INLINE=0
# and VID_SCHEDULE_FAST=1, the profile's `up … tests` with the deployed
# selector, a `down --remove-orphans --volumes`, and two reports
# (<sha>.full.xml, <sha>.deployed.xml) with `kind=full` and `kind=deployed`
# events; `--deployed -- <sel>` brings the product up first in the profile
# on the live tree and names `<sha>.live.deployed.sel-<hash>.xml`, never
# certifiable; a scoped run without --deployed uses no profile; a runner
# killed by a signal after writing one passed case of a two-case row, and a
# runner returning its own interrupt status after the same partial report,
# publish nothing and record `status=`, the row not green; a `completed:`
# status with a complete red report is published; the full-runs tripwire is
# silent across a two-pass close; the per-class seconds line names the full
# report, never the deployed one. Env: CHECKS.
set -eu
T=$(mktemp -d); RD=$(mktemp -d); trap 'rm -rf "$T" "$RD"' EXIT
export XDG_RUNTIME_DIR="$RD"
cd "$T"
git init -q
mkdir -p checks/extractors tests/invariants app .vid
cp "$CHECKS/test.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '#!/bin/sh\n# Purpose: results reader (fixture)\n[ -f "${1:-}" ] || { echo inactive; exit 0; }\ngrep "^case " "$1"\n' > checks/extractors/results.sh
cat > docker-compose.test.yml <<'YML'
x-vid-harness:
  product: product
  forbidden: none-such
  completed: [0, 1]
  inline-switch: TOY_INLINE
  schedule-fast: TOY_FAST
  deployed-selector: process-marker
  processes: [worker, beat]
services:
  product:
    build: .
    image: toy:test
    environment: &product-env
      TOY_INLINE: ${VID_INLINE:-1}
      TOY_FAST: ${VID_SCHEDULE_FAST:-0}
  worker:
    image: toy:test
    profiles: [deployed]
    environment: *product-env
  beat:
    image: toy:test
    profiles: [deployed]
    environment: *product-env
  queue:
    image: queue:1
    profiles: [deployed]
  tests:
    image: runner:1
YML
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | tests/invariants/t.sh\nROW-P01 | journey | feed | (process) | n/a | enter · store · index | REQ-002 | tests/invariants/t.sh\n```\n' > INVENTORY.md
printf '# Purpose: toy\n' > app/main.sh; printf '# Purpose: ledger\n' > tests/invariants/t.sh
printf '.vid/\nout.txt\n' > .gitignore
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root; SHA=$(git rev-parse --short=12 HEAD)
cat > "$T/../stub.$$" <<'STUB'
#!/bin/sh
printf 'inline=%s fast=%s sel=[%s] ctx=%s :: %s\n' "${VID_INLINE:-unset}" "${VID_SCHEDULE_FAST:-unset}" "${VID_SELECTOR:-}" "${VID_TEST_CONTEXT:-}" "$*" >> "$STUB_LOG"
case "$*" in
  *'up -d '*) exit 0 ;;
  *' up '*'tests'*)
    case "${STUB_MODE:-}" in
      signal) printf 'case tests/invariants/t.sh::a[ROW-001] passed 0.1\n' > .vid/ledger-results/pending.xml; exit 137 ;;
      interrupt) printf 'case tests/invariants/t.sh::a[ROW-001] passed 0.1\n' > .vid/ledger-results/pending.xml; exit 2 ;;
    esac
    if [ "${VID_INLINE:-1}" = 0 ]; then printf 'case tests/invariants/t.sh::p[ROW-P01] passed 3.0\n' > .vid/ledger-results/pending.xml
    else printf 'case tests/invariants/t.sh::a[ROW-001] passed 0.5\ncase tests/invariants/t.sh::b[ROW-001] failed 0.5\ncase tests/invariants/t.sh::p[ROW-P01] failed 1.0\n' > .vid/ledger-results/pending.xml; fi
    exit 1 ;;
esac
exit 0
STUB
mv "$T/../stub.$$" "$RD/stub.sh"; chmod +x "$RD/stub.sh"
export VID_COMPOSE="$RD/stub.sh" STUB_LOG="$RD/stub.log"
fail() { echo "deployed-profile: $*" >&2; cat "$RD/stub.log" >&2 || true; cat out.txt >&2 || true; exit 1; }
# a full run: two passes, fresh stacks, the product first
sh checks/test.sh --role close >out.txt 2>&1 || true
L=$(cat "$RD/stub.log" 2>/dev/null || true); [ -n "$L" ] || fail "the stub was never called"
printf '%s\n' "$L" | sed -n 1p | grep -q 'inline=unset fast=unset sel=\[\] .*:: -f docker-compose.test.yml up --build --exit-code-from tests tests$' || fail 'pass 1 is not the inline ledger'
printf '%s\n' "$L" | sed -n 2p | grep -q ':: -f docker-compose.test.yml down --remove-orphans --volumes$' || fail 'no down --volumes between the passes'
printf '%s\n' "$L" | sed -n 3p | grep -q '^inline=0 fast=1 .*:: -f docker-compose.test.yml --profile deployed up -d --build product beat queue worker$' || fail 'pass 2 does not bring the product up first, in the profile, with the processes and the transport, inline off and schedules fast'
printf '%s\n' "$L" | sed -n 4p | grep -q '^inline=0 fast=1 sel=\[process-marker\] .*:: -f docker-compose.test.yml --profile deployed up --exit-code-from tests tests$' || fail 'pass 2 does not run the deployed selector in the profile'
printf '%s\n' "$L" | sed -n 5p | grep -q -- '--profile deployed down --remove-orphans --volumes$' || fail 'no down --volumes after pass 2'
[ -f ".vid/ledger-results/$SHA.full.xml" ] && [ -f ".vid/ledger-results/$SHA.deployed.xml" ] || fail 'not two reports'
grep -q "kind=full report=$SHA.full.xml status=1 role=close" .vid/metrics-events && grep -q "kind=deployed report=$SHA.deployed.xml status=1 role=close" .vid/metrics-events || fail 'the two events'
# the readers: ROW-P01 green from the deployed report though red inline; the full-runs tripwire silent; per-class seconds from the full report
printf 'verdict slice=1 claimed=2 breached=0\n' >> .vid/metrics-events
OUT=$(sh checks/metrics.sh 2>/dev/null)
printf '%s\n' "$OUT" | sed -n 2p | grep -q "red 1 .*receipt .vid/ledger-results/$SHA.full.xml; deployed .vid/ledger-results/$SHA.deployed.xml" || fail "the headline: $(printf '%s\n' "$OUT" | sed -n 2p)"
sh checks/metrics.sh row-state ROW-P01 2>/dev/null | grep -q 'unverdicted (green, no verdict)' || fail 'the (process) row is not read from the deployed report'
printf '%s\n' "$OUT" | grep -q 'FLAG full-runs-per-pass' && fail 'the two-pass close tripped the full-runs tripwire'
printf '%s\n' "$OUT" | grep -q "^cost ledger-run seconds=[0-9]* .* kind=full report=$SHA.full.xml " || fail 'the per-class seconds do not name the full report'
# --deployed -- <sel>: the live tree, the profile, the product first, never certifiable
: > "$RD/stub.log"
sh checks/test.sh --role fixer --deployed -- 'tests/invariants/t.sh::p' >out.txt 2>&1 || true
sed -n 1p "$RD/stub.log" | grep -q '^inline=0 fast=1 .* ctx=\. :: .*--profile deployed up -d --build product beat queue worker$' || fail 'the scoped deployed run does not bring the product up first on the live tree'
ls .vid/ledger-results | grep -qE "^$SHA\.live\.deployed\.sel-[0-9]+\.xml$" || fail 'the scoped deployed report name'
tail -n 1 .vid/metrics-events | grep -q 'kind=scoped report=.*live.deployed' || fail 'the scoped deployed event'
# a scoped run without --deployed: no profile
: > "$RD/stub.log"; sh checks/test.sh -- x >out.txt 2>&1 || true
grep -q 'profile' "$RD/stub.log" && fail 'a scoped run used the profile'
# partial reports: a signal death and the runner's own interrupt publish nothing
rm -f .vid/ledger-results/*.xml
STUB_MODE=signal sh checks/test.sh -- x >out.txt 2>&1 && fail 'a signal death exited 0'
STUB_MODE=interrupt sh checks/test.sh -- x >out.txt 2>&1 && fail 'an interrupt exited 0'
[ -z "$(ls .vid/ledger-results)" ] || fail 'a partial report was published'
grep -q 'report=none status=137' .vid/metrics-events && grep -q 'report=none status=2' .vid/metrics-events || fail 'status= not recorded'
exit 0
