#!/bin/sh
# Purpose: selftest case — the code skeleton's state, one reader (v0.26.10.9 spec R4, R7; §5 skeleton-state).
# `plan.sh skeleton` prints `not needed` for an old init (no made=) whose HEAD holds the harness file and a ROW citing a
# path; `not started provenance=spec-only` with made=spec; `not started provenance=adopted` for the adoption shape (no
# made=, no harness file, no ROW with a path); `next part 2` after a start and part 1 done; `done` after the end. Once
# a `skeleton` event exists the tree changes nothing: the harness file and a cited path added under a started
# skeleton leave `next part 2`, and under a made=spec init with no event the reader still says not started.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "skeleton-state: $*" >&2; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
toy() { rm -rf "$T/r"; mkdir -p "$T/r/checks" "$T/r/.vid"; cd "$T/r"; git init -q; cp "$CHECKS/plan.sh" checks/
  printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | anonymous | n/a | x | REQ-001 | %s\n```\n' "$1" > INVENTORY.md
  [ "${2:-}" = harness ] && printf 'services: {}\n' > docker-compose.test.yml
  [ -n "${3:-}" ] && printf 'stage name=init state=start session=S0 at=2026-10-24T09:00:00Z\nstage name=init state=end %ssession=S0 at=2026-10-24T09:30:00Z\n' "$3" > .vid/metrics-events
  printf '.vid/\n' > .gitignore; mkdir -p tests/invariants; printf '# ROW-001\n' > tests/invariants/test_a.py; g add -A && g commit -qm root; }
rd() { sh checks/plan.sh skeleton 2>&1; }
toy 'tests/invariants/test_a.py | proved-red: abc' harness ' '; [ "$(rd)" = 'not needed' ] || fail "an old init with the harness and a cited path reads '$(rd)'"
toy 'owed: spec-only — first stage' '' 'made=spec '; [ "$(rd)" = 'not started provenance=spec-only' ] || fail "made=spec reads '$(rd)'"
toy 'owed: prerequisite — the scaffold and harness are built after init' '' ' '; [ "$(rd)" = 'not started provenance=adopted' ] || fail "the adoption shape reads '$(rd)'"
toy 'owed: prerequisite — the scaffold' harness ' '; [ "$(rd)" = 'not needed' ] || fail "an old init holding the harness file reads '$(rd)'"
toy 'owed: spec-only — first stage' '' 'made=spec '
printf 'skeleton state=start provenance=spec-only at=2026-10-24T10:00:00Z\nskeleton state=part-done part=1 at=2026-10-24T10:20:00Z\n' >> .vid/metrics-events
[ "$(rd)" = 'next part 2' ] || fail "a start with part 1 done reads '$(rd)'"
printf 'services: {}\n' > docker-compose.test.yml; printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | anonymous | n/a | x | REQ-001 | tests/invariants/test_a.py\n```\n' > INVENTORY.md; g add -A && g commit -qm 'the harness and a path'
[ "$(rd)" = 'next part 2' ] || fail "the tree changed the reading of a started skeleton: '$(rd)'"
printf 'skeleton state=part-done part=2 at=2026-10-24T10:40:00Z\n' >> .vid/metrics-events; [ "$(rd)" = 'next part 3' ] || fail "parts 1 and 2 done reads '$(rd)'"
printf 'skeleton state=part-done part=3 at=2026-10-24T11:00:00Z\nskeleton state=end sha=abc materialised=1 red=1 spec-only=0 prerequisite=0 at=2026-10-24T11:00:01Z\n' >> .vid/metrics-events
[ "$(rd)" = done ] || fail "the end reads '$(rd)'"
exit 0
