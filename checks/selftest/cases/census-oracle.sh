#!/bin/sh
# Purpose: selftest case — the census, faster, gives identical results (v0.9.7.3 spec 3.4, R4). The 0.9.7.2 census
# is kept as selftest/fixtures/census-0.9.7.2.sh, the oracle. (1) A scenario repository — duplicate exception keys,
# a rule-scoped exception beside a class-scoped one, suppression under exception precedence, ordinary and topology
# differences (the bare subject, a deploy-owed row), owed and active rules, an armed zero denominator, a two-sided
# rule, an enumeration writing to standard error, a missing extractor, silent, failing and inactive extractors, the
# report-only classes, an exception subject with whitespace at HEAD and one new — run in default and --report modes,
# serially (VID_COURT_JOBS=1) and in parallel (4): each invocation's stdout, stderr and exit status are identical,
# old against new, counters included (the census line). (2) Every census case, run with a census.sh that runs both
# and logs any difference: none. (3) The extractor invocations fell to the number of distinct extractors (a class
# extractor a rule row cites runs once), serially and in parallel. v0.9.8.1 (R13): the new census leaves no broken-pipe line where the 0.9.7.2
# oracle could, when its caller ignores SIGPIPE — such lines are dropped from the oracle's standard error before the
# comparison, never from the new census's. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
OLD="$CHECKS/selftest/fixtures/census-0.9.7.2.sh"; NEW="$CHECKS/census.sh"
fail() { echo "census-oracle: $*" >&2; cat "$T/why" >&2 2>/dev/null; exit 1; }
# same <dir> <args…>: old and new, serial and parallel, compared
same() {
  _d=$1; shift
  for _j in 1 4; do
    ( cd "$_d" && VID_COURT_EVENT=off VID_COURT_JOBS=$_j sh "$OLD" "$@" > "$T/o.out" 2> "$T/o.err"; echo $? > "$T/o.st" ) || true
    grep -v 'Broken pipe' "$T/o.err" > "$T/o.e2" || true; mv "$T/o.e2" "$T/o.err"   # v0.9.8.1 (R13): the oracle's known broken-pipe line
    ( cd "$_d" && VID_COURT_EVENT=off VID_COURT_JOBS=$_j sh "$NEW" "$@" > "$T/n.out" 2> "$T/n.err"; echo $? > "$T/n.st" ) || true
    for _x in out err st; do cmp -s "$T/o.$_x" "$T/n.$_x" || { diff "$T/o.$_x" "$T/n.$_x" > "$T/why" 2>&1 || true; fail "$_d $* (jobs=$_j): $_x differs"; }; done
  done
}
# --- (1) the scenario ---------------------------------------------------------------------------------------------
S="$T/s"; mkdir -p "$S/checks/extractors" "$S/tests"; cd "$S"; git init -q
LOG="$T/inv.log"; : > "$LOG"
x() { printf '#!/bin/sh\n# Purpose: stub extractor\necho %s >> %s\n%s\n' "$1" "$LOG" "$2" > "checks/extractors/$1.sh"; }
x dead-path.alpha "printf 'orphan site-a d1\norphan site-b d2\norphan site-c d3\norphan site-d d4\norphan owed-subj d5\nok fine\npopulation 3\norphan site-e\n'"
x divergence.beta "printf 'orphan live-x drift one\norphan live-y drift two\n'"
x dead-path.topology "printf 'orphan q:jobs consumer\norphan q:sched c\norphan q:other c\norphan jobs bare\n'"
x vacuity.v "printf 'orphan v1 x\nok v2\n'"; x rendered.r "printf 'orphan r1 x\n'"; x strength.s "printf 'orphan s1 x\n'"
x dead-path.silent ':'; x dead-path.broken 'echo partial; exit 3'; x dead-path.idle "echo 'inactive no substrate yet'"
x invariant.gamma "printf 'orphan g1 x\norphan site-c y\nok g2\n'"
printf '' > tests/x.py
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
grammar: 0.9.3
ROW-001 | behavior | owed-subj | anon | n/a | x | REQ-001 | owed: prerequisite — later
ROW-002 | behavior | q:sched | anon | n/a | x | REQ-001 | owed: paid by /vid deploy — the platform half
exception | EXC-001 | site-a | dead-path | first reason
exception | EXC-002 | site-a | dead-path | the same key, second reason
exception | EXC-003 | site-b | RULE-001 | rule-scoped
exception | EXC-004 | site-c | invariant | the class word, never a rule orphan
exception | EXC-005 | has space | dead-path | at HEAD
suppression | SUP-001 | site-a | dead-path | gap under an exception | fix-by S9
suppression | SUP-002 | site-d | dead-path | a real gap | fix-by S9
suppression | SUP-003 | site-b | RULE-001 | rule-scoped gap | fix-by S9
difference | DIF-001 | live-x | test-a | prod-a | ordinary
difference | DIF-002 | jobs | test-b | prod-b | bare topology
difference | DIF-003 | q:jobs | test-c | prod-c | full topology
rule | RULE-001 | guarded sites | checks/extractors/dead-path.alpha.sh | 1 | tests/x.py
rule | RULE-002 | owed rule | printf 'site-c\nsite-z\n' :: printf 'site-z\n' | 0 | owed: census-armed — later
rule | RULE-003 | armed zero denominator | true :: true | 1 | tests/x.py
rule | RULE-004 | an arm on stderr | sh -c 'echo s1; echo oops >&2' | 1 | tests/x.py
rule | RULE-005 | a missing extractor | checks/extractors/nope.sh | 1 | tests/x.py
rule | RULE-006 | a plain enumeration | printf 'p1\np2\n' | 1 | tests/x.py | origin: REQ-001
rule | RULE-007 | a cited class extractor | checks/extractors/invariant.gamma.sh | 0 | tests/x.py | proved-red: abc
rule | RULE-008 | owed, empty | true :: true | 1 | owed: census-armed — later
rule | RULE-009 | state-machine status: a>b b>c | checks/extractors/state-machine.status.sh | 1 | tests/x.py
```
INV
printf '#!/bin/sh\n# Purpose: stub state machine\necho state-machine.status >> %s\nprintf "s1 a>b\\ns2 c>a\\ns3 b\\n"\n' "$LOG" > checks/extractors/state-machine.status.sh
git add -A && git -c user.email=v@s -c user.name=v commit -qm scenario
same "$S"; same "$S" --report
awk '/^exception \| EXC-005/ { print; print "exception | EXC-006 | new space | dead-path | not at HEAD"; next } { print }' INVENTORY.md > i && mv i INVENTORY.md
same "$S"; same "$S" --report
# (3) the invocations: twelve distinct extractor files are run (eleven class or rule extractors and the state machine;
# nope.sh does not exist), each once
for _j in 1 4; do : > "$LOG"; ( cd "$S" && VID_COURT_EVENT=off VID_COURT_JOBS=$_j sh "$NEW" > /dev/null 2>&1 ) || true
  [ "$(sort "$LOG" | uniq -d | grep -c . || true)" = 0 ] || { sort "$LOG" | uniq -c > "$T/why"; fail "an extractor ran twice (jobs=$_j)"; }
  [ "$(grep -c . "$LOG")" = 11 ] || { sort "$LOG" | uniq -c > "$T/why"; fail "not the eleven distinct extractors (jobs=$_j)"; }
  : > "$LOG"; ( cd "$S" && VID_COURT_EVENT=off VID_COURT_JOBS=$_j sh "$OLD" > /dev/null 2>&1 ) || true
  [ "$(grep -c . "$LOG")" -gt 11 ] || fail "the fixture no longer shows the old double run (jobs=$_j)"
done
# --- (2) every census case through a comparing census.sh ----------------------------------------------------------
cd "$T"; mkdir shim; cp -R "$CHECKS/." shim/
MM="$T/mismatch"; N="$T/compared"; : > "$MM"; : > "$N"
cat > shim/census.sh <<SHIM
#!/bin/sh
# Purpose: census-oracle shim — runs the 0.9.7.2 census and the new one, serially and in parallel, logs any difference, then runs the new one for its caller
D=\$(mktemp -d)
for j in 1 4; do
  VID_COURT_EVENT=off VID_COURT_JOBS=\$j sh "$OLD" "\$@" > "\$D/o.out" 2> "\$D/o.err" < /dev/null; echo \$? > "\$D/o.st"
  grep -v 'Broken pipe' "\$D/o.err" > "\$D/o.e2" || true; mv "\$D/o.e2" "\$D/o.err"
  VID_COURT_EVENT=off VID_COURT_JOBS=\$j sh "$NEW" "\$@" > "\$D/n.out" 2> "\$D/n.err" < /dev/null; echo \$? > "\$D/n.st"
  for k in out err st; do cmp -s "\$D/o.\$k" "\$D/n.\$k" || echo "\$(pwd) \$* jobs=\$j: \$k differs" >> "$MM"; done
done
rm -rf "\$D"; echo x >> "$N"
exec sh "$NEW" "\$@"
SHIM
for c in census census-rendered census-parallel census-subject-space census-parallel-order census-memory census-stderr census-state-machine topology strength-grain; do
  _n0=$(grep -c . "$N" || true)
  CHECKS="$T/shim" sh "$CHECKS/selftest/cases/$c.sh" > /dev/null 2>&1 || true
  [ "$(grep -c . "$N" || true)" -gt "$_n0" ] || fail "case $c never ran the census through the shim"
done
[ ! -s "$MM" ] || { cp "$MM" "$T/why"; fail 'a census case differs, old against new'; }
exit 0
