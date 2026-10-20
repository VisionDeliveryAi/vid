#!/bin/sh
# Purpose: selftest case — one entry per pass of the tests (v0.26.10.6 spec R11). The viewer fixture with planted passes:
# an iterate request's two passes in one run (its wait counted on the first only; its asked time from the request;
# start-up and running from overhead=; the first's cleanup from the teardown naming its receipt; attempts 1 and 2), a
# pass stopped at its limit, one by a service, one cancelled, one found void, two passes with `report=none` beside two
# teardowns with `report=none` (no cleanup joined), a pass with no overhead= (running and start-up null), a close batch
# of three parts, a proof run; and requests with no pass: failed to start, cancelled, running, waiting, stopped (none).
# Convicts unless each entry and outcome is as recorded, the batch is one entry, and a past snapshot holds none of the
# latest-only entries. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-econ-tests: $*" >&2; exit 1; }
view_project "$T/repo"
rq() { mkdir -p ".vid/requests/$1"; printf 'type=iterate\nrole=builder\nrows=1\ncreated=1767265200\n' > ".vid/requests/$1/request"; printf '%s\n' "$2" > ".vid/requests/$1/state"; }
lr() { _t=$1; shift; vev "$_t" "ledger-run $* why=\"x\""; }
rq 20260101T110000Z-a001 done
lr 11:02 'seconds=100 kind=scoped report=p1.xml status=0 role=builder tree=x run=RUN1 waited=30 request=20260101T110000Z-a001 type=iterate rows=2 silence=1 startup=1 limit=1 try=1-builder-1 overhead=40'
vev 11:02:05 'teardown seconds=5 report=p1.xml'
lr 11:03 'seconds=50 kind=scoped report=p2.xml status=1 role=builder tree=x run=RUN1 waited=30 request=20260101T110000Z-a001 type=iterate rows=2 silence=1 startup=1 limit=1 try=1-builder-1 overhead=10'
lr 11:04 'seconds=60 kind=scoped report=none status=130 role=builder run=RUN2 request=20260101T110000Z-a002 type=iterate rows=1 capped=yes stop=silent'
lr 11:05 'seconds=60 kind=scoped report=none status=1 role=builder run=RUN3 request=20260101T110000Z-a003 type=iterate rows=1 stopped=service:db'
lr 11:06 'seconds=60 kind=scoped report=none status=130 role=builder run=RUN4 request=20260101T110000Z-a004 type=iterate rows=1 cancelled=yes'
lr 11:07 'seconds=60 kind=scoped report=v1.xml status=0 role=builder run=RUN5 request=20260101T110000Z-a005 type=iterate rows=1'; vev 11:08 'invalidated slice=1 report=v1.xml its tree was wrong'
lr 11:09 'seconds=60 kind=scoped report=none status=1 role=builder run=RUN6 request=20260101T110000Z-a006 type=iterate rows=1 overhead=5'
lr 11:09:30 'seconds=60 kind=scoped report=none status=1 role=builder run=RUN7 request=20260101T110000Z-a007 type=iterate rows=1 overhead=5'
vev 11:09:40 'teardown seconds=3 report=none'; vev 11:09:50 'teardown seconds=4 report=none'
lr 11:10 'seconds=70 kind=scoped report=p8.xml status=0 role=builder run=RUN8 request=20260101T110000Z-a008 type=iterate rows=1'
for c in 1 2 3; do lr 11:1$c "seconds=30 kind=full report=b$c.xml status=0 role=close run=RUNB$c request=20260101T111000Z-b001/$c type=close rows=3 batch=20260101T111000Z-b001 overhead=5"; done
vev 11:14 'close-batch id=20260101T111000Z-b001 chunks=3 retried=0 adopted=0 stacks-max=2 wall=100 chunk-seconds-sum=90'
lr 11:15 'seconds=20 kind=scoped report=r.proof.xml status=0 role=orchestrator run=RUNP request=20260101T110000Z-a009 type=prove-red rows=1 purpose=proof overhead=5'
rq 20260101T112000Z-c001 failed-to-start; rq 20260101T112000Z-c002 cancelled; rq 20260101T112000Z-c003 running; printf '1767266460\n' > .vid/requests/20260101T112000Z-c003/running-at
rq 20260101T112000Z-c004 queued; rq 20260101T112000Z-c005 stopped
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
tp() { vel "$N" "{\"ticket\":\"$1\"," | grep -F '"outcome":"' || fail "no pass of $1"; }
tp 20260101T110000Z-a001 | sed -n 1p | grep -qF '"batch":null,"type":"iterate","role":"builder","try":"1-builder-1","step":"S1","rows":2,"asked":"2026-01-01T11:00:00Z","started":"2026-01-01T11:00:20Z","ended":"2026-01-01T11:02:00Z","waited":30,"ran":60,"startup":40,"cleanup":5,"outcome":"passed","proof":false,"attempt":1}' || fail "the first pass: $(tp 20260101T110000Z-a001 | sed -n 1p)"
tp 20260101T110000Z-a001 | sed -n 2p | grep -qF '"waited":0,"ran":40,"startup":10,"cleanup":null,"outcome":"failed","proof":false,"attempt":2}' || fail "the second pass of the run: $(tp 20260101T110000Z-a001 | sed -n 2p)"
oc() { tp "$1" | grep -qF "\"outcome\":\"$2\"" || fail "$1 is not $2: $(tp "$1")"; }
oc 20260101T110000Z-a002 limit; oc 20260101T110000Z-a003 service-stopped; oc 20260101T110000Z-a004 cancelled; oc 20260101T110000Z-a005 void
oc 20260101T110000Z-a008 passed; tp 20260101T110000Z-a008 | grep -qF '"ran":null,"startup":null' || fail "a pass with no overhead=: $(tp 20260101T110000Z-a008)"
for t in a006 a007; do tp 20260101T110000Z-$t | grep -qF '"cleanup":null' || fail "a report=none pass joined a teardown: $(tp 20260101T110000Z-$t)"; done
[ "$(vel "$N" '"batch":"20260101T111000Z-b001"' | wc -l | tr -d ' ')" = 3 ] || fail 'the close batch does not have three parts'
tp 20260101T111000Z-b001/2 | grep -qF '"batch":"20260101T111000Z-b001","type":"close"' || fail 'a part does not keep its chunk'
vel "$N" '"batches":[' | grep -qF '"batches":[{"ticket":"20260101T111000Z-b001","parts":3,"elapsed":100,"retried":0}]' || fail "the batch: $(vel "$N" '"batches":[')"
tp 20260101T110000Z-a009 | grep -qF '"proof":true' || fail 'the proof run'
oc 20260101T112000Z-c001 failed-to-start; oc 20260101T112000Z-c002 cancelled; oc 20260101T112000Z-c003 running; oc 20260101T112000Z-c004 waiting
tp 20260101T112000Z-c002 | grep -qF '"started":null,"ended":null' || fail 'the cancelled request has times'
vel "$N" '{"ticket":"20260101T112000Z-c005",' && fail 'a stopped request with no pass is an entry'
P="$T/out/20260101T112000Z-checkpoint.html"
vel "$P" '{"ticket":"20260101T112000Z-c00' && fail 'a past snapshot holds a latest-only entry'
exit 0
