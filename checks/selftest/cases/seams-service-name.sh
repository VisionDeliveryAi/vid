#!/bin/sh
# Purpose: selftest case — a single-label host is no outside service (FIX-BATCH-T1 §12, B-9). A toy with a seam table and
# a staged compose file reaching the product and a worker by their service names (`http://app:8000`, `http://worker/health`):
# checks/seams.sh refuses nothing. The same file with a dotted outside host no seam row covers beside them is refused as
# before, naming that host and neither service; and a URL with a user part (`postgresql://admin:…@db.…`) is judged by the
# host after the @, refused, never skipped as the single label `admin`; a host a template cuts short
# (`api-{region}.…`, `pay-%s.…`) is refused as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "seams-service-name: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"; git init -q
printf '# toy\n```vid-inventory\nseam | SEAM-001 | examplepay | card charges | chosen: D-001 | credentials: named | probe: probed(2026-11-01) | evidence: tests/contracts/pay.json | quirks: none | match: examplepay\n```\n' > INVENTORY.md
printf 'services:\n  tests:\n    environment:\n      APP_URL: http://app:8000\n      WORKER_URL: http://worker/health\n' > docker-compose.test.yml
git add -A
sh "$CHECKS/seams.sh" > "$T/out" 2>&1 || fail 'a service name of the harness was refused as an outbound call'
printf '      PAY_URL: https://api.payments.examplecharge.com/v1\n' >> docker-compose.test.yml; git add -A
if sh "$CHECKS/seams.sh" > "$T/out" 2>&1; then fail 'a dotted outside host no seam row covers passed'; fi
grep -q 'api.payments.examplecharge.com' "$T/out" || fail 'the refusal does not name the outside host'
grep -qE '://(app|worker)([^.a-z]|$)' "$T/out" && fail 'the refusal names a service name'
# a URL with a user part: its host is what follows the @, judged, never skipped as the single label before it
printf 'services:\n  tests:\n    environment:\n      DB_URL: postgresql://admin:madeup1@db.examplevendor.com:5432/main\n' > docker-compose.test.yml; git add -A
if sh "$CHECKS/seams.sh" > "$T/out" 2>&1; then fail 'an outside host after a user part passed as a single label'; fi
grep -q 'db.examplevendor.com' "$T/out" || fail 'the refusal does not name the host after the user part'
# a password's punctuation never cuts the user part short
printf 'services:\n  tests:\n    environment:\n      DB_URL: postgresql://admin:made(up)1'"'"'x@db.examplevendor.com:5432/main\n' > docker-compose.test.yml; git add -A
if sh "$CHECKS/seams.sh" > "$T/out" 2>&1; then fail 'a password with ( ) or a quote let the outside host pass as a single label'; fi
grep -q 'db.examplevendor.com' "$T/out" || fail 'with punctuation in the password, the refusal does not name the host'
# a dotted host followed by a quoted string holding @: the host is judged under its first reading
for v in "('https://hooks.examplechat.com','ops@db')" "['https://api.examplecharge.com','admin@localhost']"; do
  printf 'services:\n  tests:\n    environment:\n      X_HOOKS: "%s"\n' "$v" > docker-compose.test.yml; git add -A
  if sh "$CHECKS/seams.sh" > "$T/out" 2>&1; then fail "a dotted host before a quoted string holding @ passed: $v"; fi
done
# a credentialed URL to a harness service (user, password and host all single labels): no refusal
printf 'services:\n  tests:\n    environment:\n      DATABASE_URL: postgres://app:madeup2@db:5432/app\n' > docker-compose.test.yml; git add -A
sh "$CHECKS/seams.sh" > "$T/out" 2>&1 || fail 'a credentialed URL to a harness service was refused'
# a template cuts the host short: judged as before, never skipped as a single label
for u in 'https://api-{region}.examplevendor.com/v1' 'https://pay-%s.examplecharge.com'; do
  printf 'services:\n  tests:\n    environment:\n      X_URL: %s\n' "$u" > docker-compose.test.yml; git add -A
  if sh "$CHECKS/seams.sh" > "$T/out" 2>&1; then fail "a template-cut outside host passed: $u"; fi
done
echo 'seams-service-name: ok'
