#!/bin/sh
# Purpose: selftest case — measure and pick (v0.9.6 spec 3.9, R9; §7 case
# 16). A gated toy run, stubbed `docker stats` and `docker info`: measure
# samples the running environment's own compose project (a product at 300
# MB and a tests container at 212: env-mb=512), subtracts other projects'
# containers (1000 + 500 MB from another folder) but not this repository's
# own (700 MB), and records the median case seconds and the Compose
# version. With the default 2048 MB headroom, Docker totals of 8192, 4700,
# 4200 and 3000 MB pick k = 3, 2, 1 and 1 (the last from k=0, "one
# environment is still used"); below 2 the pick prints what Docker's memory
# would need to be for 2 and for 3 — 4572 MB and 5084 MB — as whole GB.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; wait; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-pick: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'testenv and a reader'
export DSTUB_HOME="$(pwd -P)"
printf 'c1\tother-db-1\t/elsewhere/proj\t1000MiB\nc2\tother-web-1\t/elsewhere/proj\t500MiB\nc3\trepo-dev-1\t%s\t700MiB\n' "$(pwd -P)" > "$T/others"
measure() { touch "$T/hold"; release_sampled "$T/hold"; STUB_HOLD="$T/hold" DOCKER_TOTAL_MB=$1 sh checks/testenv.sh measure --rows ROW-001 -- 'tests/x' > "$T/out" 2>&1 || fail "measure at $1 MB"; }
pick() { sh checks/testenv.sh pick > "$T/out" 2>&1 || fail "pick at $1 MB"; grep -q "^testenv pick k=$2 " "$T/out" || fail "Docker at $1 MB did not pick k=$2"; }
measure 8192
grep -qx 'env-mb=512' .vid/testenv || fail 'the environment was not measured at its peak of 512 MB'
grep -qx 'other-mb=1500' .vid/testenv || fail "other projects' memory is not 1500 MB (this repository's own counted?)"
grep -qx 'docker-mb=8192' .vid/testenv && grep -qx 'compose=2.29.1' .vid/testenv && grep -qx 'case-seconds=0.1' .vid/testenv || fail 'Docker total, Compose version or case seconds missing'
pick 8192 3
grep -q 'short:' "$T/out" && fail 'k=3 printed a memory question'
measure 4700; pick 4700 2
measure 4200; pick 4200 1
grep -q 'Docker memory for 2: 4572 MB · for 3: 5084 MB' "$T/out" || fail 'the figures for 2 and 3 are not 4572 and 5084 MB'
grep -q "short: raise Docker's memory to 5 GB for 2 environments, or 5 GB for 3, instead of 1" "$T/out" || fail 'no memory question at k=1'
measure 3000; pick 3000 1
grep -q 'computed=0 ' "$T/out" && grep -q 'k=0: one environment is still used' "$T/out" || fail 'k=0 is not reported as one environment'
exit 0
