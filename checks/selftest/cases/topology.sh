#!/bin/sh
# Purpose: selftest case — the topology census (v0.9.3 spec 3.4, R5; §7 case
# 13). A toy scaffold (routings, schedules, registered tasks) and a fixture
# `dead-path.topology.sh` honouring the seed contract, through the real
# census. Convicts unless: nothing declared → `inactive`, skipped through
# the class path, exit 0 — and the same extractor cited as a RULE row's
# census command is the zero-population failure the design avoids; a routed
# queue no declared process consumes → orphan, the commit blocked; the same
# queue named by a ratified deploy-owed row → printed as a ratified
# divergence, not an orphan; a routing under an empty `processes:` →
# orphan; a schedule-only product naming an unregistered task → armed,
# orphan; the consumer declared and the task registered → clean. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors app tests/invariants
cp "$CHECKS/census.sh" checks/
cat > checks/extractors/dead-path.topology.sh <<'X'
#!/bin/sh
# Purpose: dead-path.topology (fixture) — routings and schedules joined to the declared processes and registered tasks.
R=app/routes.conf; S=app/schedule.conf
[ -s "$R" ] || [ -s "$S" ] || { echo 'inactive no routing or schedule declared'; exit 0; }
PROCS=$(awk '/^x-vid-harness:/{i=1; next} i && /^[^ ]/{i=0} i && $1=="processes:" { v=$0; sub(/^[^:]*:/,"",v); gsub(/[][,]/," ",v); print v }' docker-compose.test.yml)
CONS=''
for p in $PROCS; do CONS="$CONS $(awk -v s="  $p:" '$0==s {f=1; next} f && /^  [^ ]/ {f=0} f && $1=="command:" { print $3 }' docker-compose.test.yml | tr ',' ' ')"; done
if [ -s "$R" ]; then for q in $(awk '{print $3}' "$R" | sort -u); do
  case " $CONS " in *" $q "*) echo "ok queue:$q" ;; *) echo "orphan queue:$q no declared process consumes it" ;; esac; done; fi
if [ -s "$S" ]; then while read -r _ n t; do
  if grep -qx "$t" app/tasks.conf 2>/dev/null; then echo "ok schedule:$n"; else echo "orphan schedule:$n names unregistered task $t"; fi; done < "$S"; fi
X
compose() { printf 'x-vid-harness:\n  product: product\n  processes: [%s]\nservices:\n  product:\n    build: .\n%s\n' "$1" "$2" > docker-compose.test.yml; }
inv() { printf '# toy\n```vid-inventory\ngrammar: 0.9.3\n%s\n```\n' "$1" > INVENTORY.md; }
fail() { echo "topology: $*" >&2; cat out.txt >&2; exit 1; }
compose '' ''; inv 'ROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2'
: > app/routes.conf; : > app/schedule.conf; : > app/tasks.conf
# 1. nothing declared: inactive, skipped
sh checks/census.sh >out.txt 2>&1 || fail 'an unarmed topology census failed the commit'
grep -q '^census dead-path.topology: inactive no routing or schedule declared' out.txt || fail 'not reported inactive'
#    the rule-row shape of the same instance: the zero-population failure
printf '# Purpose: ledger\n' > tests/invariants/t.sh
inv 'rule | RULE-009 | every routed queue has a consumer | checks/extractors/dead-path.topology.sh | 1 | tests/invariants/t.sh'
if sh checks/census.sh >out.txt 2>&1; then fail 'the rule-row shape of the instance passed with nothing declared'; fi
grep -q 'RULE-009.*zero-denominator' out.txt || fail 'the rule-row shape did not meet the zero-population rule'
inv 'ROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2'
# 2. a routed queue no declared process consumes: orphan, the commit blocked
printf 'route index_listing search\nroute send_digest mail\n' > app/routes.conf
compose 'worker' '  worker:
    image: p:1
    profiles: [deployed]
    command: consume search'
if sh checks/census.sh >out.txt 2>&1; then fail 'a routed queue with no consumer passed'; fi
grep -q 'FAIL  dead-path.topology  queue:mail  no declared process consumes it' out.txt || fail 'the orphan is not named'
grep -q 'FAIL  dead-path.topology  queue:search' out.txt && fail 'a consumed queue was named'
# 3. the same queue named by a ratified deploy-owed row: printed, not an orphan
inv 'ROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2
ROW-002 | behavior | queue:mail | n/a | n/a | the platform'"'"'s mail relay consumes the mail queue | REQ-002 | owed: paid by /vid deploy gate 2 — the platform'"'"'s consumer drains it'
sh checks/census.sh >out.txt 2>&1 || fail 'a queue named by a ratified deploy-owed row still blocked'
grep -q '^DIF   dead-path.topology  queue:mail .*ratified ROW-002' out.txt || fail 'not printed as a ratified divergence'
# 4. a routing under an empty processes: → orphan
inv 'ROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2'
compose '' ''
if sh checks/census.sh >out.txt 2>&1; then fail 'a routing with no declared process passed'; fi
grep -q 'queue:search  no declared process consumes it' out.txt || fail 'the empty processes: orphan'
# 5. a schedule-only product naming an unregistered task: armed, orphan
: > app/routes.conf; printf 'schedule nightly_expiry expire_links\n' > app/schedule.conf; printf 'send_digest\n' > app/tasks.conf
if sh checks/census.sh >out.txt 2>&1; then fail 'an unregistered scheduled task passed'; fi
grep -q 'FAIL  dead-path.topology  schedule:nightly_expiry  names unregistered task expire_links' out.txt || fail 'the schedule-only orphan'
# 6. wired: the task registered, the queues consumed
printf 'expire_links\n' >> app/tasks.conf; printf 'route index_listing search\nroute send_digest mail\n' > app/routes.conf
compose 'worker' '  worker:
    image: p:1
    profiles: [deployed]
    command: consume search,mail'
sh checks/census.sh >out.txt 2>&1 || fail 'the wired topology was convicted'
grep -q 'census dead-path.topology: population=3 ok=3 orphans=0' out.txt || fail 'the wired census line'
exit 0
