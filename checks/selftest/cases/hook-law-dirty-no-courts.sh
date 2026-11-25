#!/bin/sh
# Purpose: selftest case — law the commit does not carry, or may not write: the courts do not run, and every other check
# still speaks (FB-4 C2). Stub courts: an unstaged edit of a law file beside a staged decision with two labels is refused
# by=law-dirty,decisions-label, both named, no court run, one line saying so, and the order of commits, the unstaged law file in it (an
# untracked one too); a protected path staged
# without VID_ROLE=fix beside the same decision likewise. Law-dirty alone is refused as before, and a missing
# checks/labels.sh keeps the reasons found before it. In a merge the order lists what the merge itself adds, never a file
# the other branch brings. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-law-dirty-no-courts: $*" >&2; cat .vid/out >&2 2>/dev/null; exit 1; }
mkdir -p .vid; printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md; g add -A; g commit -qm decisions
dec() { printf -- '- **D-001** a thing | why: a reason | enforced: convention | applies-to: REQ-001 | scope: project\n' >> DECISIONS.md; g add DECISIONS.md; }
clean() { g reset -q --hard; rm -rf .ran/*; }
refuses() { : > .vid/hook-times; if sh checks/hooks/pre-commit > .vid/out 2>&1; then fail "passed: $1"; fi
  [ "$(sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times)" = "$2" ] || fail "$1: not by=$2 but $(sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times)"; }
nocourts() { [ -z "$(ls .ran)" ] || fail "$1: a court ran: $(ls .ran | tr '\n' ' ')"; [ "$(grep -c 'the courts did not run' .vid/out)" = 1 ] || fail "$1: no line saying the courts did not run"; }
clean; dec; printf '# more\n' >> checks/lawfiles
refuses 'law edited, not staged, and a decision with two labels' law-dirty,decisions-label; nocourts 'law not staged'
grep -q 'law files are edited but not staged' .vid/out && grep -q 'more than one label' .vid/out || fail 'law not staged: not both reasons said'
grep -A 2 '^The order of commits the law asks for' .vid/out | sed 1d > .vid/ord
printf '  1. checks/lawfiles\n  2. DECISIONS.md\n' | cmp -s - .vid/ord || fail 'law not staged: the order of commits is not said'
clean; dec; printf '# more\n' >> checks/lawfiles; g add checks/lawfiles
refuses 'a protected path, and a decision with two labels' protected-paths,law-standalone,decisions-label; nocourts 'a protected path'
grep -q 'protected paths staged without VID_ROLE=fix' .vid/out && grep -q 'more than one label' .vid/out || fail 'a protected path: not both reasons said'
# a law file untracked is in the order too
clean; dec; printf '#!/bin/sh\n# Purpose: new law\n' > checks/new.sh
refuses 'a new law file, not staged, and a decision with two labels' law-dirty,decisions-label; nocourts 'a new law file'
grep -A 2 '^The order of commits the law asks for' .vid/out | sed 1d > .vid/ord; rm checks/new.sh
printf '  1. checks/new.sh\n  2. DECISIONS.md\n' | cmp -s - .vid/ord || fail 'a new law file: the order does not name it'
clean; stage one; printf '# more\n' >> checks/lawfiles
refuses 'law edited, not staged' law-dirty; nocourts 'law not staged, alone'
# a merge: the order lists the conflicts resolved by hand, never the other branch's own files
clean; M=$(git rev-parse --abbrev-ref HEAD); printf 'docker-compose.test.yml whole\n' >> checks/lawfiles; printf 'a: 1\n' > docker-compose.test.yml; printf 'one\n' > app/c.txt; g add -A; g commit -qm law
g checkout -q -b side; printf 'a: 2\n' > docker-compose.test.yml; printf 'two\n' > app/c.txt; printf 's\n' > app/s1.txt; printf 's\n' > app/s2.txt; g add -A; g commit -qm side
g checkout -q "$M"; printf 'a: 3\n' > docker-compose.test.yml; printf 'three\n' > app/c.txt; g add -A; g commit -qm main
if g merge -q side > .vid/out 2>&1; then fail 'the merge had no conflict'; fi
printf 'a: 4\n' > docker-compose.test.yml; printf 'four\n' > app/c.txt; g add -A
refuses 'a merge resolving a law file and another by hand' law-standalone
printf '  1. docker-compose.test.yml\n  2. app/c.txt\n' > .vid/want
sed -n '/^The order of commits the law asks for/,$p' .vid/out | sed 1d | cmp -s - .vid/want || fail 'a merge: the order is not what the merge itself adds'
g reset -q --hard
# labels.sh missing ends the hook there, with what was found before it
clean; g rm -q --cached checks/labels.sh; rm checks/labels.sh; g commit -qm 'no labels.sh'; dec; printf '#!/bin/sh\necho\n' > app/a.sh; g add app/a.sh
refuses 'labels.sh missing' purpose-header,decisions-label
grep -q 'labels.sh, the decision-label join, is missing' .vid/out || fail 'labels.sh missing: not said'
exit 0
