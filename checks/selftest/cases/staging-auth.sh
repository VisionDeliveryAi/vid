#!/bin/sh
# Purpose: selftest case — the standing staging authorization and develop's own staging deploy (v0.26.10.8 spec R6,
# R8; §5 staging-auth). On the toy two-stage product (fixtures/stages.sh): `staging-auth on|off --words` writes
# `staging-auth state=on|off words="…"`, the newest standing; without STAGES.md it is refused, one line, recording
# nothing. Stage 1 closed, a correction after it, develop active (the gate on): with the authorization on, `deploy
# --target staging --by develop` is accepted for the newest close's tag (the owner's deploy is refused while develop
# runs), and metrics.sh deploy-check takes `--by develop` through; refused when off, for production, and for HEAD
# while only the owner's hold holds the stage; accepted for HEAD while the setup hold holds it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "staging-auth: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
dev_on() { sed 's/^run:.*/run: active/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
  printf 'run state=active at=2026-10-20T10:00:00Z\nstage name=develop state=start session=S1 at=2026-10-20T10:00:01Z\n' >> .vid/metrics-events; }
dd() { sh checks/stages.sh deploy --target "$1" --by develop --platform none > "$T/out" 2>&1; }
# repo: stage 1 closed and tagged, then (in a copy taken before the close) the holds
st_close_repo "$T/r"
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002
cp -R . "$T/owner"; cp -R . "$T/setup"
# without STAGES.md: refused
mkdir "$T/none"; ( cd "$T/none"; git init -q; mkdir -p .vid checks; cp "$CHECKS/stages.sh" "$CHECKS/event.sh" checks/
  if sh checks/stages.sh staging-auth on --words 'yes' > "$T/out" 2>&1; then exit 1; fi
  [ "$(grep -c . "$T/out")" -eq 1 ] && grep -q '^staging-auth: refused — this project has no STAGES.md' "$T/out" && [ ! -s .vid/metrics-events ] ) || fail 'staging-auth without STAGES.md was not refused in one line, recording nothing'
# on and off, the newest standing
sh checks/stages.sh staging-auth on --words 'yes, put each stage on it' > "$T/out" 2>&1 || fail 'staging-auth on was refused'
grep -q '^staging-auth state=on words="yes, put each stage on it" at=' .vid/metrics-events || fail 'the on record lacks the words'
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || fail 'stage 1 did not close'
TAG1=$(git rev-parse --short=12 'vid/stage-1^{commit}')
printf '# a correction\n' >> app/main.py; g commit -qam 'a correction after the close'
dev_on
if sh checks/stages.sh deploy --target staging --platform none > "$T/out" 2>&1; then fail "the owner's deploy ran while develop is active"; fi
dd staging || fail 'develop was refused with the authorization on'
grep -q "^candidate: stage 1 vid/stage-1 $TAG1 " "$T/out" || fail "develop's candidate is not the newest close's tag"
sh checks/metrics.sh deploy-check --target staging --by develop > "$T/out" 2>&1 || true
grep -qE 'a build is running|candidate cannot be read' "$T/out" && fail "deploy-check did not take --by develop through: $(cat "$T/out")"
grep -q "^base: $TAG1 " "$T/out" || fail "deploy-check --by develop did not read the tag: $(head -n 2 "$T/out")"
sh checks/metrics.sh deploy-check --target staging --by develop --record > "$T/out" 2>&1 || true
grep -qx 'deploy-check staging ready rows=0 ahead=0' "$T/out" || fail "develop's staging check of the newest close's tag is not ready from its record: $(cat "$T/out")"
if dd production; then fail 'develop deployed to production'; fi
grep -q '^deploy: refused — develop deploys to staging only' "$T/out" || fail 'the production refusal does not say so'
sh checks/stages.sh staging-auth off --words 'stop deploying to staging on your own' > /dev/null 2>&1
grep -q '^staging-auth state=off words="stop deploying to staging on your own" at=' .vid/metrics-events || fail 'the off record lacks the words'
if dd staging; then fail 'develop deployed with the authorization off'; fi
grep -q '^deploy: refused — the standing staging authorization is off' "$T/out" || fail 'the off refusal does not say so'
# HEAD: refused under the owner's hold alone, accepted under the setup hold
for k in owner setup; do
  cd "$T/$k"
  W='hold after this stage'; [ "$k" = setup ] && W='staging setup'
  sh checks/stages.sh hold --after 1 --words "$W" > /dev/null 2>&1 || fail "the $k hold was refused"
  sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 && grep -q '^held: ' "$T/out" || fail "the $k close did not hold"
  printf '# a fix\n' >> app/main.py; g commit -qam 'a fix while held'
  sh checks/stages.sh staging-auth on --words 'yes' > /dev/null 2>&1
  if [ "$k" = owner ]; then
    if dd staging; then fail "develop deployed HEAD under the owner's hold alone"; fi
    grep -q "^deploy: refused — develop deploys HEAD only while the staging setup holds the stage" "$T/out" || fail 'the HEAD refusal does not say so'
  else
    dd staging || fail 'develop was refused HEAD under the setup hold'
    grep -q "^candidate: HEAD $(git rev-parse --short=12 HEAD) " "$T/out" || fail 'under the setup hold the candidate is not HEAD'
  fi
done
exit 0
