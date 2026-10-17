#!/bin/sh
# Purpose: selftest case — upgrading a 0.9.2 project (v0.9.3 spec 3.17; §7
# case 16's upgrade half). A toy project under `grammar: 0.9.2` that already
# routes work with inline execution (a routing declaration, a harness
# contract with no processes) upgraded through the four commits by the real
# pre-commit and commit-msg hooks. Convicts unless: (1) checks/ refreshed
# with VID_ROLE=fix, standalone — without the topology extractor — is
# accepted; (2) INVENTORY.md alone, the grammar flip and `(process)` on the
# trigger row, is accepted; (3) the topology extractor committed WITHOUT the
# compose change is refused by the census naming the routed queue, and the
# extractor WITH the compose file's contract keys, profile and consumer,
# one standalone law commit, is accepted; (4) the rest — CLAUDE.md prose —
# is an ordinary commit, accepted; and the grammar-reading courts then read
# 0.9.3. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/hooks checks/extractors app tests/invariants
# the 0.9.2 project: its courts (the refreshed set minus what commit 1 adds), its hooks, its tree
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh harness.sh metrics.sh lawfiles; do cp "$CHECKS/$c" checks/; done
cp "$CHECKS/hooks/pre-commit" "$CHECKS/hooks/commit-msg" checks/hooks/
printf '```vid-placement\napp/\n```\n\nThe law file.\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.sh .md .yml .conf\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
printf '# toy\n\nPreview:\n\n    docker compose -f docker-compose.test.yml up --build product\n' > README.md
printf 'x-vid-harness:\n  product: product\n  forbidden: none-such\nservices:\n  product:\n    build: .\n    image: toy:test\n  tests:\n    image: runner:1\n' > docker-compose.test.yml
printf '# Purpose: toy routing declaration\n' > app/routing.sh; printf 'route send_digest digest\n' > app/routes.conf
O='owed: prerequisite — a clock the harness lacks; paid at slice 2'
printf '# toy\n```vid-inventory\ngrammar: 0.9.2\nROW-001 | behavior | REQ-001 | n/a | n/a | the daily digest trigger is registered and fires | REQ-001 | %s\n```\n' "$O" > INVENTORY.md
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'the 0.9.2 project

Decisions: none'
git config core.hooksPath checks/hooks; chmod +x checks/hooks/*
fail() { echo "upgrade: $*" >&2; cat out.txt >&2 2>/dev/null || true; exit 1; }
commit() { g commit -qm "$1

Decisions: none — the 0.9.3 upgrade, spec 3.17" >out.txt 2>&1; }
# 1. checks/ refreshed, standalone, VID_ROLE=fix — NOT the topology extractor
cp "$CHECKS/observe.sh" "$CHECKS/brief.sh" "$CHECKS/prd.sh" checks/; cp "$CHECKS/hooks/post-commit" checks/hooks/; chmod +x checks/hooks/*
g add checks
VID_ROLE=fix commit 'upgrade 1: checks/ refreshed' || fail 'commit 1 (checks/ refreshed) was refused'
# 2. the grammar flip, INVENTORY.md alone
sed -e 's/^grammar: 0.9.2$/grammar: 0.9.3/' -e 's/ | REQ-001 | n\/a | n\/a | the daily/ | REQ-001 | (process) | n\/a | the daily/' INVENTORY.md > i && mv i INVENTORY.md
g add INVENTORY.md
commit 'upgrade 2: the grammar flip' || fail 'commit 2 (the grammar flip) was refused'
# 3. the topology extractor without the compose change: refused by the census
cat > checks/extractors/dead-path.topology.sh <<'X'
#!/bin/sh
# Purpose: dead-path.topology (this toy project's, generated as init would) — routed queues joined to the declared processes.
[ -s app/routes.conf ] || { echo 'inactive no routing or schedule declared'; exit 0; }
PROCS=$(awk '/^x-vid-harness:/{i=1; next} i && /^[^ ]/{i=0} i && $1=="processes:" { v=$0; sub(/^[^:]*:/,"",v); gsub(/[][,]/," ",v); print v }' docker-compose.test.yml)
CONS=''; for p in $PROCS; do CONS="$CONS $(awk -v s="  $p:" '$0==s {f=1; next} f && /^  [^ ]/ {f=0} f && $1=="command:" { print $3 }' docker-compose.test.yml | tr ',' ' ')"; done
for q in $(awk '{print $3}' app/routes.conf | sort -u); do case " $CONS " in *" $q "*) echo "ok queue:$q" ;; *) echo "orphan queue:$q no declared process consumes it" ;; esac; done
X
chmod +x checks/extractors/dead-path.topology.sh
g add checks/extractors/dead-path.topology.sh
if VID_ROLE=fix commit 'upgrade 3 without the harness'; then fail 'the topology extractor without the compose change was accepted'; fi
grep -q 'queue:digest  no declared process consumes it' out.txt || fail 'the census did not name the routed queue'
#    the same commit WITH the compose file's contract keys, profile and consumer: accepted
printf 'x-vid-harness:\n  product: product\n  forbidden: none-such\n  completed: [0, 1]\n  inline-switch: TOY_INLINE\n  schedule-fast: TOY_FAST\n  deployed-selector: deployed\n  processes: [worker]\nservices:\n  product:\n    build: .\n    image: toy:test\n  worker:\n    image: toy:test\n    profiles: [deployed]\n    command: consume digest\n  tests:\n    image: runner:1\n' > docker-compose.test.yml
g add docker-compose.test.yml checks/extractors/dead-path.topology.sh
VID_ROLE=fix commit 'upgrade 3: topology and the harness together' || fail 'commit 3 with the consumer declared was refused'
# 4. the rest, an ordinary commit
printf '\nA spawned agent reads its brief — the quotations and the role'"'"'s required inputs — and nothing else is mandatory.\n' >> CLAUDE.md
g add CLAUDE.md
commit 'upgrade 4: the rest' || fail 'commit 4 (the prose) was refused'
[ "$(git log --oneline | wc -l | tr -d ' ')" -eq 5 ] || fail 'not four upgrade commits above the project'
sh checks/census.sh >out.txt 2>&1 || fail 'the upgraded project fails its census'
grep -q 'census dead-path.topology: population=1 ok=1' out.txt || fail 'the topology census is not armed and joined'
sh checks/metrics.sh row-state ROW-001 | grep -q '^ROW-001: owed: prerequisite' || fail 'the grammar-reading courts do not read 0.9.3 after the upgrade'
exit 0
