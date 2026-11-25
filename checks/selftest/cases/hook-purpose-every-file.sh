#!/bin/sh
# Purpose: selftest case — a check that named the first file names every one (FB-4 C2). Stub courts: two new source
# files with no Purpose: header are both named, by=purpose-header once; a DECISIONS line citing two tests that do not
# exist names both, by=decisions-promissory once; in ticket mode two lines citing a ticket and a step the records do
# not hold are both named. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-purpose-every-file: $*" >&2; cat .vid/out >&2 2>/dev/null; exit 1; }
mkdir -p .vid; printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md; g add -A; g commit -qm decisions
try() { : > .vid/hook-times; if sh checks/hooks/pre-commit > .vid/out 2>&1; then fail "passed: $1"; fi
  [ "$(sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times)" = "$1" ] || fail "by=$(sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times), not $1"
  for m in "$2" "$3"; do grep -qF "$m" .vid/out || fail "not named: $m"; done; }
printf '#!/bin/sh\necho a\n' > app/a.sh; printf '#!/bin/sh\necho b\n' > app/b.sh; g add app
try purpose-header "'app/a.sh'" "'app/b.sh'"
g reset -q --hard
dec() { printf -- '- **D-00%s** a thing | why: a reason | enforced: %s | scope: project\n' "$1" "$2" >> DECISIONS.md; g add DECISIONS.md; }
dec 1 'tests/invariants/test_a.py, tests/invariants/test_b.py'
try decisions-promissory "'tests/invariants/test_a.py'" "'tests/invariants/test_b.py'"
g reset -q --hard; printf 'mode: tickets\n' > .vid/RUN-STATE.md
dec 1 'ticket 7'; dec 2 'step S9'
try decisions-ticket "'enforced: ticket 7'" "'enforced: step S9'"
exit 0
