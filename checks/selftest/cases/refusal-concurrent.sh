#!/bin/sh
# Purpose: selftest case — two refusals at once keep both records, at the run's home (v0.9.7.3 spec 3.5, R5). A run
# home (.vid/RUN-STATE.md) and a builder's worktree whose .vid/home names it, each with the stub census refusing:
# their two commits, refused at the same moment, leave two attempt directories under the home's .vid/refusals, each
# with its meta and the census output, and two court-refused events in the home's events; the builder's worktree
# keeps no record of its own. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/home"; cd "$T/home"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "refusal-concurrent: $*" >&2; cat "$T/out.a" "$T/out.b" >&2 2>/dev/null; exit 1; }
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/
printf '#!/bin/sh\n# Purpose: stub census\nif [ -f .fail/census ]; then printf "FAIL  RULE-001  site-%%s  unguarded\\n" "$(basename "$PWD")"; exit 1; fi\necho ok\n' > checks/census.sh
g add -A && g commit -qm 'the run'
mkdir -p .vid; printf '# RUN-STATE\n\nrun: active\nplan: required\n' > .vid/RUN-STATE.md
git worktree add -q "$T/b" -b builder 2>/dev/null
mkdir -p "$T/b/.vid" "$T/b/.fail" "$T/b/.ran"; printf '%s\n' "$T/home" > "$T/b/.vid/home"
: > .fail/census; : > "$T/b/.fail/census"
stage home; (cd "$T/b" && printf 'b\n' >> app/x.txt && g add app/x.txt)
( sh checks/hooks/pre-commit > "$T/out.a" 2>&1 & ); ( cd "$T/b" && sh checks/hooks/pre-commit > "$T/out.b" 2>&1 & )
n() { _n=$(grep -c '^court-refused ' .vid/metrics-events 2>/dev/null || true); echo "${_n:-0}"; }
i=0; until [ "$(n)" -ge 2 ] || [ "$i" -ge 60 ]; do sleep 1; i=$((i + 1)); done
[ "$(ls .vid/refusals | grep -c .)" = 2 ] || fail 'not two attempt directories at the home'
for a in $(ls .vid/refusals); do [ -f ".vid/refusals/$a/meta" ] && [ -f ".vid/refusals/$a/census.out" ] || fail "attempt $a lacks its record"; done
grep -h '^court=census' .vid/refusals/*/meta | sort > "$T/m"
grep -qx 'court=census rule=RULE-001 subject=site-home' "$T/m" && grep -qx 'court=census rule=RULE-001 subject=site-b' "$T/m" || fail 'the two refusals are not both recorded'
[ "$(grep -c '^court-refused court=census ' .vid/metrics-events)" = 2 ] || fail 'not two events at the home'
[ ! -d "$T/b/.vid/refusals" ] || fail 'the builder worktree kept a record of its own'
exit 0
