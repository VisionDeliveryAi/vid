#!/bin/sh
# Purpose: selftest case — a resolution counts only on a commit that holds the change and has landed (v0.26.10.3 R2;
# §5 amend-branch-no-clear). ROW-002 is to confirm after a `law-changed` at L on main. Convicts unless: an `amended`
# for it made on a branch forked before L leaves it to confirm (even once that branch is merged); one made after L on
# a branch not yet merged leaves it to confirm; and once that branch is merged into main (fast-forward), it is cleared.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q; mkdir -p checks .vid; cp "$CHECKS/metrics.sh" checks/
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "amend-branch-no-clear: $*" >&2; exit 1; }
tc() { sh checks/metrics.sh to-confirm 2>/dev/null | grep -c '^to-confirm row=ROW-002 ' || true; }
at() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
printf '.vid/\n' > .gitignore; printf 'base\n' > f; g add -A; g commit -qm base; MAIN=$(git symbolic-ref --short HEAD)
g checkout -qb early; printf 'early\n' > e; g add e; g commit -qm 'early work'; S1=$(git rev-parse --short=12 HEAD)
g checkout -q "$MAIN"; printf 'the law changed\n' > law; g add law; g commit -qm 'the change'; L=$(git rev-parse --short=12 HEAD)
printf 'law-changed row=ROW-002 sha=%s item=REQ-001 at=%s\n' "$L" "$(at)" >> .vid/metrics-events
[ "$(tc)" = 1 ] || fail 'ROW-002 is not to confirm after the change'
printf 'amended row=ROW-002 sha=%s by=obligation at=%s\n' "$S1" "$(at)" >> .vid/metrics-events
[ "$(tc)" = 1 ] || fail 'an amendment on a branch forked before the change cleared it'
g merge -q --no-edit early > /dev/null 2>&1 || fail 'the early branch did not merge'
[ "$(tc)" = 1 ] || fail 'an amendment made before the change cleared it once its branch was merged'
g checkout -qb late; printf 'late\n' > l; g add l; g commit -qm 'late work'; S2=$(git rev-parse --short=12 HEAD); g checkout -q "$MAIN"
printf 'amended row=ROW-002 sha=%s by=obligation at=%s\n' "$S2" "$(at)" >> .vid/metrics-events
[ "$(tc)" = 1 ] || fail 'an amendment on a branch not yet merged cleared it'
g merge -q --ff-only late > /dev/null 2>&1 || fail 'the late branch did not fast-forward'
[ "$(tc)" = 0 ] || fail 'the merged amendment made after the change did not clear it'
exit 0
