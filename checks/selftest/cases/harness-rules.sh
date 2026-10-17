#!/bin/sh
# Purpose: selftest case — the court for declared rules (v0.9.7.0.10 spec
# 3.4, 3.6; R9, R12). Without `rules:` under x-vid-harness a harness with
# no readiness declared passes, as before. With `rules: 1`: a product with
# a healthcheck, a datastore with one that the product waits for with
# `condition: service_healthy`, a one-shot service waited for with
# `condition: service_completed_successfully`, and tests waiting for the
# product with `condition: service_healthy`, pass; refused, each naming
# the service — the datastore with no healthcheck, the product waiting for
# it only to start (the list form), the product with no healthcheck, the
# tests waiting for the product only to start, the tests not waiting at
# all; the one-line form of an entry (`db: {condition: …}`) is read as
# the block form, both ways; and (revision 5) a started-only entry in the
# tests' depends_on — a service the product calls only while serving,
# waited for by nobody at start — passes. The init fixture: the template
# carries `rules: 2` and, filled for a toy stack, passes the court.
# v0.9.7.0.11 (3.2, R2): with `rules: 2` the readiness checks hold as
# before (a datastore with no healthcheck refused), and rule 4's: a
# `case-limit:` of whole seconds above 0 with the tests service naming
# VID_CASE_LIMIT passes; no case-limit:, a limit of 0 or not a number,
# and a tests service that never names VID_CASE_LIMIT are refused, each
# saying so. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "harness-rules: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"; mkdir -p tests/invariants
printf '# toy\n\n    docker compose -f docker-compose.test.yml up --build product\n' > README.md
# harness <rules line or empty> <services>
harness() { printf 'x-vid-harness:\n  product: product\n%s  completed: [0, 1]\nservices:\n%s\n' "$1" "$2" > docker-compose.test.yml; }
OLD='  product:
    build: .
    image: toy-product:test
    depends_on:
      - db
  db:
    image: db:1
  tests:
    image: runner:1
    depends_on:
      - product'
GOOD='  product:
    build: .
    image: toy-product:test
    depends_on:
      db:
        condition: service_healthy
      migrate:
        condition: service_completed_successfully
    healthcheck:
      test: ["CMD", "probe", "/ready"]
  db:
    image: db:1
    healthcheck:
      test: ["CMD", "db-ready"]
  migrate:
    image: toy-migrate:1
  tests:
    image: runner:1
    depends_on:
      product:
        condition: service_healthy'
court() { sh "$CHECKS/harness.sh" > "$T/out" 2>&1; }
refused() { # <what> <message fragment>
  if court; then fail "$1 passed"; fi
  grep -qF -- "$2" "$T/out" || fail "$1: the refusal does not name it ('$2')"
}
harness '' "$OLD"; court || fail 'a harness without rules: was refused'
# v0.9.7.0.10 revision 5: a service the product calls only while serving, started by the tests' depends_on, waited for by nobody
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk '{ print } $0 == "        condition: service_healthy" && t { print "      search:\n        condition: service_started"; t = 0 } /^  tests:/ { t = 1 }'; printf '  search:\n    image: search:1\n')"
grep -q '^      search:$' docker-compose.test.yml || fail 'the fixture did not add the started-only entry'
court || fail "a started-only entry in the tests' depends_on was refused"
# the one-line form of a depends_on entry, `<name>: {condition: …}`, is read as the block form
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk '$0 == "      db:" { getline; print "      db: {condition: service_healthy}"; next } $0 == "      product:" { getline; print "      product: {condition: service_healthy}"; next } { print }')"
court || fail 'the one-line form of service_healthy was refused'
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk '$0 == "      db:" { getline; print "      db: {condition: service_started}"; next } { print }')"
refused 'the one-line form of a start-only wait' "the product waits for service 'db' only to start (service_started)"
harness '  rules: 1
' "$GOOD"; court || fail 'the harness keeping the rules was refused'
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk '/^  db:/ { d=1 } /^  migrate:/ { d=0 } d && /healthcheck|db-ready/ { next } { print }')"
refused 'a datastore with no healthcheck' "service 'db', which the product depends on, declares no healthcheck"
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk 'NR==4 { print "    depends_on:\n      - db\n      - migrate"; skip=4; next } skip { skip--; next } { print }')"
refused 'the product waiting for its datastore only to start' "the product waits for service 'db' only to start"
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk '/^    healthcheck:/ && !h { h=1; getline; next } { print }')"
refused 'a product with no healthcheck' "the product service 'product' declares no healthcheck"
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | sed 's/^        condition: service_healthy$/XX/' | awk '$0=="XX" { n++; if (n == 2) { print "        condition: service_started"; next } print "        condition: service_healthy"; next } { print }')"
refused 'tests waiting for the product only to start' "the tests service waits for the product 'product' only to start (service_started), not to be ready"
harness '  rules: 1
' "$(printf '%s\n' "$GOOD" | awk '/^  tests:/ { t=1 } t && /depends_on|product:|condition/ { next } { print }')"
refused 'tests not waiting for the product' "the tests service waits for the product 'product' not at all, not to be ready"
# v0.9.7.0.11 (R2): rules: 2 — rules 1–4
GOOD2=$(printf '%s\n' "$GOOD" | awk '{ print } /^  tests:/ { print "    environment:\n      VID_CASE_LIMIT: ${VID_CASE_LIMIT:-600}" }')
harness '  rules: 2
  case-limit: 600
' "$GOOD2"; court || fail 'a harness keeping the four rules was refused'
harness '  rules: 2
  case-limit: 600
' "$(printf '%s\n' "$GOOD2" | awk '/^  db:/ { d=1 } /^  migrate:/ { d=0 } d && /healthcheck|db-ready/ { next } { print }')"
refused 'rules: 2 with a datastore with no healthcheck' "rules: 2 — service 'db', which the product depends on, declares no healthcheck"
harness '  rules: 2
' "$GOOD2"; refused 'rules: 2 with no case-limit:' "carries no case-limit: of whole seconds above 0 ('none')"
for _v in 0 ten; do harness "  rules: 2
  case-limit: $_v
" "$GOOD2"; refused "rules: 2 with case-limit: $_v" "carries no case-limit: of whole seconds above 0 ('$_v')"; done
harness '  rules: 2
  case-limit: 600
' "$GOOD"; refused 'rules: 2 with tests not naming VID_CASE_LIMIT' 'the tests service does not reference VID_CASE_LIMIT'
# the init fixture: the template, filled for a toy stack
TPL="$CHECKS/../templates/docker-compose.test.yml"
if [ -f "$TPL" ]; then
  awk '/^x-vid-harness:/ { x=1; next } x && /^[^ ]/ { x=0 } x && $1 == "rules:" && $2 == "2" { y=1 } x && $1 == "case-limit:" && $2 == "600" { z=1 } END { exit !(y && z) }' "$TPL" || fail 'the template does not declare rules: 2 and case-limit: 600'
  sed -e 's/{{PRODUCT_IMAGE}}/toy-product:test/g; s/{{PROCESS_NAMES}}/worker/; s/{{PROCESS_NAME}}/worker/; s/{{TRANSPORT_SERVICE}}/queue/; s/{{TRANSPORT_IMAGE}}/queue:1/' \
      -e 's/{{IN_PROCESS_SERVER_TOKENS}}/live_server/; s/{{RUNNER_COMPLETED_STATUSES}}/0, 1/; s/{{PRODUCT_READY_CHECK}}/["CMD", "probe", "\/ready"]/' \
      -e 's/{{[A-Z_]*}}/x/g' "$TPL" > docker-compose.test.yml
  court || fail 'the template, filled, was refused by the court'
fi
exit 0
