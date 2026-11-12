#!/bin/sh
# Purpose: selftest case — the census prints fixed results on a scenario, serially and in parallel (v0.9.7.3 spec 3.4,
# R4; fitted in 0.26.10.28.3, R5). (1) A scenario repository — duplicate exception keys, a rule-scoped exception
# beside a class-scoped one, suppression under exception precedence, ordinary and topology differences (the bare
# subject, a deploy-owed row), owed and active rules, an armed zero denominator, a two-sided rule, an enumeration
# writing to standard error, a missing extractor, silent, failing and inactive extractors, the report-only classes,
# an exception subject with whitespace at HEAD and one new — run in default and --report modes, serially
# (VID_COURT_JOBS=1) and in parallel (4): each invocation's stdout, stderr and exit status are the lines a run at
# 92e0195 printed, written below, counters included (the census line). (2) The extractor invocations are the number
# of distinct extractors (a class extractor a rule row cites runs once), serially and in parallel. The comparison
# with the 0.9.7.2 census, the oracle this case was named for, went in 0.26.10.28.3. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
NEW="$CHECKS/census.sh"
fail() { echo "census-oracle: $*" >&2; cat "$T/why" >&2 2>/dev/null; exit 1; }
# the expected lines, from a run at 92e0195: one stdout for every invocation; the five failing lines on stderr, after
# the new whitespace subject's refusal once EXC-006 is in, and before the rejection in default mode
cat > "$T/x.out" <<'EXP'
EXC   dead-path.alpha  site-a  (EXC-001: first reason)
FAIL  dead-path.alpha  site-b  d2
FAIL  dead-path.alpha  site-c  d3
SUP   dead-path.alpha  site-d  (SUP-002 — extractor gap, to-do)
PEND  dead-path.alpha  owed-subj  d5 (partner row owed — reported, not failed)
FAIL  dead-path.alpha  site-e  
census dead-path.alpha: population=10 ok=1 orphans=3 exc=1 sup=1 pending=1 vac=0 rend=0 str=0
census dead-path.idle: inactive no substrate yet
DIF   dead-path.topology  q:jobs  consumer — a platform-only consumer (ratified DIF-002; its platform half is paid at deploy gate 2)
DIF   dead-path.topology  q:sched  c — a platform-only consumer (ratified ROW-002; its platform half is paid at deploy gate 2)
FAIL  dead-path.topology  q:other  c
DIF   dead-path.topology  jobs  bare — a platform-only consumer (ratified DIF-002; its platform half is paid at deploy gate 2)
census dead-path.topology: population=4 ok=0 orphans=1 exc=0 sup=0 pending=0 vac=0 rend=0 str=0
DIF   divergence.beta  live-x  live: drift one  (ratified DIF-001)
FAIL  divergence.beta  live-y  drift two
census divergence.beta: population=2 ok=0 orphans=1 exc=0 sup=0 pending=0 vac=0 rend=0 str=0
FAIL  invariant.gamma  g1  x
EXC   invariant.gamma  site-c  (EXC-004: the class word, never a rule orphan)
census invariant.gamma: population=3 ok=1 orphans=1 exc=1 sup=0 pending=0 vac=0 rend=0 str=0
REND  rendered.r  r1  x (report-only §9 — the computed value differs from the canvas value; promote or delete on measured FP rate)
census rendered.r: population=1 ok=0 orphans=0 exc=0 sup=0 pending=0 vac=0 rend=1 str=0
STR   strength.s  s1  x (report-only — a Tier-0 row whose strongest assertion is existence; promote or delete on measured FP rate)
census strength.s: population=1 ok=0 orphans=0 exc=0 sup=0 pending=0 vac=0 rend=0 str=1
VAC   vacuity.v  v1  x (report-only — promote or delete on measured FP rate)
census vacuity.v: population=2 ok=1 orphans=0 exc=0 sup=0 pending=0 vac=1 rend=0 str=0
FAIL  RULE-001  site-a  d1
EXC   RULE-001  site-b  (EXC-003: rule-scoped)
FAIL  RULE-001  site-c  d3
FAIL  RULE-001  site-d  d4
PEND  RULE-001  owed-subj  d5 (partner row owed — reported, not failed)
FAIL  RULE-001  site-e  
census RULE-001: 10 sites, 4 guarded (orphans=4 exc=1 sup=0 pending=1)
PEND  RULE-002  site-c  unguarded (partner row owed — reported, not failed)
census RULE-002: 2 sites, 1 guarded (orphans=0 exc=0 sup=0 pending=1)
census RULE-003: 0 sites, 0 guarded (orphans=0 exc=0 sup=0 pending=0)
census RULE-006: 2 sites, 2 guarded (orphans=0 exc=0 sup=0 pending=0)
FAIL  RULE-007  g1  x
FAIL  RULE-007  site-c  y
census RULE-007: 3 sites, 1 guarded (orphans=2 exc=0 sup=0 pending=0)
census RULE-008: 0 sites, 0 guarded (orphans=0 exc=0 sup=0 pending=0)
PEND  RULE-008  zero-denominator — rule ratified, test owed, no sites yet (fail-closed once armed)
FAIL  RULE-009  s2  undeclared-transition:c>a
census RULE-009: 3 sites, 2 guarded (orphans=1 exc=0 sup=0 pending=0)

divergences (ratified — the green ledger did not validate these):
    DIF-001  live-x  test=test-a  prod=prod-a  ordinary
    DIF-002  jobs  test=test-b  prod=prod-b  bare topology
    DIF-003  q:jobs  test=test-c  prod=prod-c  full topology

suppressions (extractor to-do — never counted toward the ceremony threshold):
    SUP-001  dead-path  site-a  gap: gap under an exception  fix-by: fix-by S9
    SUP-002  dead-path  site-d  gap: a real gap  fix-by: fix-by S9
    SUP-003  RULE-001  site-b  gap: rule-scoped gap  fix-by: fix-by S9

census: population=43 orphans=13 exceptions=3 suppressed=1 pending=4 vacuity-reports=1 rendered-reports=1 strength-reports=1 · note: exception EXC-005's subject has whitespace, which no orphan's subject can carry (at HEAD)
EXP
cat > "$T/x.fails" <<'EXP'
FAIL  dead-path.broken  extractor exited 3 — a broken census is a failure, never a pass.
FAIL  dead-path.silent  silent-empty — an extractor declares 'inactive <reason>' when its substrate is absent; silence is how a census dies.
FAIL  RULE-003  zero-denominator — the census command enumerates nothing; a rule must not silently survive the renaming of what it watches.
FAIL  RULE-004  census command wrote to standard error — a failing arm must never silently shrink a population: oops
FAIL  RULE-005  census command 'checks/extractors/nope.sh' does not exist — promissory denominators are invalid.
EXP
REJ='ViD census: rejected — every orphan is fixed, or carries a ratified exception/suppression row (standalone law commit).'
SPACE="ViD census: rejected — exception EXC-006's subject has whitespace, which no orphan's subject can carry: 'new space'"
{ cat "$T/x.fails"; printf '%s\n' "$REJ"; } > "$T/x.err.head"; cp "$T/x.fails" "$T/x.err.head.report"
{ printf '%s\n' "$SPACE"; cat "$T/x.err.head"; } > "$T/x.err.new"; { printf '%s\n' "$SPACE"; cat "$T/x.fails"; } > "$T/x.err.new.report"
# expect <dir> <status> <expected stderr> <args…>: today's census, serial and parallel, prints the expected lines
expect() {
  _d=$1; printf '%s\n' "$2" > "$T/x.st"; _e=$3; shift 3
  for _j in 1 4; do
    ( cd "$_d" && VID_COURT_EVENT=off VID_COURT_JOBS=$_j sh "$NEW" "$@" > "$T/n.out" 2> "$T/n.err"; echo $? > "$T/n.st" ) || true
    for _x in out:x.out "err:$_e" st:x.st; do
      cmp -s "$T/${_x#*:}" "$T/n.${_x%%:*}" || { diff "$T/${_x#*:}" "$T/n.${_x%%:*}" > "$T/why" 2>&1 || true; fail "$_d $* (jobs=$_j): ${_x%%:*} is not the expected lines"; }
    done
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
expect "$S" 1 x.err.head; expect "$S" 0 x.err.head.report --report
awk '/^exception \| EXC-005/ { print; print "exception | EXC-006 | new space | dead-path | not at HEAD"; next } { print }' INVENTORY.md > i && mv i INVENTORY.md
expect "$S" 1 x.err.new; expect "$S" 0 x.err.new.report --report
# (2) the invocations: twelve distinct extractor files are run (eleven class or rule extractors and the state machine;
# nope.sh does not exist), each once
for _j in 1 4; do : > "$LOG"; ( cd "$S" && VID_COURT_EVENT=off VID_COURT_JOBS=$_j sh "$NEW" > /dev/null 2>&1 ) || true
  [ "$(sort "$LOG" | uniq -d | grep -c . || true)" = 0 ] || { sort "$LOG" | uniq -c > "$T/why"; fail "an extractor ran twice (jobs=$_j)"; }
  [ "$(grep -c . "$LOG")" = 11 ] || { sort "$LOG" | uniq -c > "$T/why"; fail "not the eleven distinct extractors (jobs=$_j)"; }
done
exit 0
