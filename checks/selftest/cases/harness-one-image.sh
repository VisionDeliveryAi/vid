#!/bin/sh
# Purpose: selftest case — one product image (v0.9.2 spec 3.6 item 4, R21;
# §7.12). Fixture harnesses carrying the x-vid-harness key: (1) a tests
# service naming the product's image under another tag convicts; (2) a
# test file starting the product in-process — the contract's forbidden
# token — convicts; (3) v0.9.7.0.10 (3.4, R8): a tests service building
# its own image passes — a service that is neither the product nor one of
# its processes may build — and a second product build, a declared process
# carrying a build:, convicts; (4) the clean harness with a README preview
# command naming the product service passes; (5) a README without that
# command, or naming a second compose file, and a second compose file at
# the root, convict; (6) a compose file without the key (pre-0.9.2) is
# reported, never convicted. v0.9.3 (3.3, §7 case 12's court half): (7) a
# declared process in the deployed profile on the product's byte-identical
# image reference, with no build, passes; a process on the product
# repository under another tag, a process service outside the profile, a
# `processes:` entry with no service, and a tests service naming the image
# all convict; (8) through the real pre-commit hook, a commit bundling a
# compose-file change with product code is refused and the compose change
# alone is accepted (the whole file is a law region). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p tests/invariants
harness() { # $1 = the services block
  printf 'x-vid-harness:\n  product: product\n  forbidden: live_server serve_in_process\nservices:\n%s\n' "$1" > docker-compose.test.yml
}
CLEAN='  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
      target: release
    image: toy-product:test
    command: serve
  tests:
    image: runner:1
    depends_on:
      - product
    volumes:
      - ${VID_TEST_CONTEXT:-.}:/app:ro
    environment:
      VID_PRODUCT_URL: http://product:8000
    command: run'
printf '# toy\n\nPreview what the ledger certified:\n\n    docker compose -f docker-compose.test.yml up --build product\n' > README.md
printf '# harness client: reaches the product at VID_PRODUCT_URL\n' > tests/invariants/harness.py
# 4. the clean harness passes
harness "$CLEAN"
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || { echo 'harness-one-image: the clean harness was convicted' >&2; sh "$CHECKS/harness.sh" >&2; exit 1; }
# 1. the tests service runs the product's image
harness "$(printf '%s\n' "$CLEAN" | sed 's/image: runner:1/image: toy-product:dev/')"
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a tests service on the product image passed' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q "names the product's image" || exit 1
# 3. v0.9.7.0.10 (R8): a tests image of its own passes; a second product build — a process that builds — convicts
harness "$(printf '%s\n' "$CLEAN" | sed 's/    image: runner:1/    build:\n      context: ${VID_TEST_CONTEXT:-.}\n      target: test/')"
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || { echo 'harness-one-image: a tests service building its own image was convicted' >&2; sh "$CHECKS/harness.sh" >&2; exit 1; }
printf 'x-vid-harness:\n  product: product\n  forbidden: live_server serve_in_process\n  completed: [0, 1]\n  deployed-selector: deployed\n  processes: [worker]\nservices:\n%s\n  worker:\n    build:\n      context: ${VID_TEST_CONTEXT:-.}\n      target: worker\n    image: toy-product:test\n    profiles: [deployed]\n' "$CLEAN" > docker-compose.test.yml
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a second product build passed' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q '2 services among the product and its processes carry a build:' || exit 1
# 2. a test starting the product in-process
harness "$CLEAN"
printf '# fixture: the product started inside the tests process\nfrom runner import live_server\n' > tests/invariants/conftest.py
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: an in-process server token passed' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q "in-process server token 'live_server'" || exit 1
rm tests/invariants/conftest.py
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || exit 1
# 5. the preview command: missing, naming another file, or a second compose file
printf '# toy\n\nRun the tests with sh checks/test.sh.\n' > README.md
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a README without the preview command passed' >&2; exit 1; fi
printf '# toy\n\n    docker compose -f docker-compose.local.yml up --build product\n    docker compose -f docker-compose.test.yml up --build product\n' > README.md
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a README naming a second compose file passed' >&2; exit 1; fi
printf '# toy\n\n    docker compose -f docker-compose.test.yml up --build product\n' > README.md
printf 'services: {}\n' > docker-compose.local.yml
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a second compose file at the root passed' >&2; exit 1; fi
rm docker-compose.local.yml
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || exit 1
# 6. pre-0.9.2: no key, reported
printf 'services:\n  tests:\n    image: runner:1\n    volumes:\n      - ./:/app\n' > docker-compose.test.yml
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/harness.sh" | grep -q 'no x-vid-harness key (pre-0.9.2 harness, reported' || exit 1
# 7. the deployed shape (v0.9.3 3.3)
proc() { # $1=process service block $2=processes: list
  printf 'x-vid-harness:\n  product: product\n  forbidden: live_server serve_in_process\n  completed: [0, 1]\n  deployed-selector: deployed\n  processes: [%s]\nservices:\n%s\n%s\n' "$2" "$CLEAN" "$1" > docker-compose.test.yml
}
W='  worker:
    image: toy-product:test
    profiles: [deployed]
    command: consume
  queue:
    image: queue-server:1
    profiles: [deployed]'
proc "$W" worker
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || { echo 'harness-one-image: a declared process on the exact image was convicted' >&2; sh "$CHECKS/harness.sh" >&2; exit 1; }
proc "$(printf '%s\n' "$W" | sed 's/    profiles: \[deployed\]/    profiles:\n      - deployed/')" worker
sh "$CHECKS/harness.sh" >/dev/null 2>&1 || { echo 'harness-one-image: the list form of profiles was not read' >&2; exit 1; }
proc "$(printf '%s\n' "$W" | sed 's/image: toy-product:test/image: toy-product:older/')" worker
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a process on another tag passed' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q "not the product's image reference 'toy-product:test' byte for byte" || exit 1
proc "$(printf '%s\n' "$W" | sed '3d')" worker
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a process outside the profile passed' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q 'is outside the deployed profile' || exit 1
proc "$W" 'worker, beat'
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a processes: entry with no service passed' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q "names 'beat' and no service" || exit 1
proc "$W" worker; sed 's/image: runner:1/image: toy-product:test/' docker-compose.test.yml > c && mv c docker-compose.test.yml
if sh "$CHECKS/harness.sh" >/dev/null 2>&1; then echo 'harness-one-image: a tests service on the product image passed beside a declared process' >&2; exit 1; fi
sh "$CHECKS/harness.sh" 2>&1 | grep -q "service 'tests' names the product's image" || exit 1
# 8. the whole compose file is a law region: bundled with product code → refused; alone → accepted
H=$(mktemp -d); ( cd "$H" && git init -q && mkdir -p checks/hooks app
  for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh lawfiles; do cp "$CHECKS/$c" checks/; done
  cp "$CHECKS/hooks/pre-commit" checks/hooks/
  printf '```vid-placement\napp/\n```\n' > CLAUDE.md
  printf '```vid-allowed-extensions\n.py .md .sh .yml\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
  printf 'Import court: enforce\n' > ARCHITECTURE.md
  printf 'services:\n  product:\n    build: .\n' > docker-compose.test.yml
  printf '# Purpose: toy\n' > app/main.py
  git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
  printf 'x-vid-harness:\n  product: product\n  completed: [0, 1]\nservices:\n  product:\n    build: .\n' > docker-compose.test.yml
  printf '# Purpose: toy, and a feature\n' > app/main.py
  git add -A
  if sh checks/hooks/pre-commit >out.txt 2>&1; then echo 'harness-one-image: a compose change bundled with product code passed the hook' >&2; exit 1; fi
  grep -q 'docker-compose.test.yml (whole)' out.txt || { cat out.txt >&2; exit 1; }
  git reset -q app/main.py
  sh checks/hooks/pre-commit >out.txt 2>&1 || { echo 'harness-one-image: the compose change alone was refused' >&2; cat out.txt >&2; exit 1; }
) || { rm -rf "$H"; exit 1; }
rm -rf "$H"
# the template itself carries the key and the placeholders the court reads —
# where the template exists (the plugin repository). A project's checks/ has
# no templates/ beside it (init copies checks/ alone): there the assertion is
# skipped, never failed (v0.9.4 fix).
TPL="$CHECKS/../templates/docker-compose.test.yml"
if [ -f "$TPL" ]; then grep -q '^x-vid-harness:' "$TPL" || exit 1; fi
exit 0
