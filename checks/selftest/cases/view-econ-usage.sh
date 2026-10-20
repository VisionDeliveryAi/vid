#!/bin/sh
# Purpose: selftest case — one usage entry per agent, never two (v0.26.10.6 spec R10). The viewer fixture with planted
# costs: an agent with a `usage` record and a build-cost (one entry, in kinds, its largest call from the build-cost);
# a Codex job with a `usage` record and an events file (one entry, the record's); a Codex job with only its events file
# (in kinds, its cached input out of its input); the fixture's older build-cost (a total); two agents linked to one
# brief and its build-cost (one entry, no agent named); a reported total; and each `survived` reason — superseded,
# every passed row later broken (false even though its step closed after), ended with no hand-back, a row later kept,
# its step closed after its hand-back (true), a hand-back with no acceptance (null). Convicts unless each entry is as
# recorded. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-econ-usage: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/briefs/2 .vid/jobs
U='input=10 cache-read=100 cache-write=20 cache-write-1h=5 output=7 scope=agent'
lnk() { vev 11:00 "agent-start session=S1 agent=$1 type=vid:$3"; vev 11:00:10 "agent-brief agent=$1 brief=.vid/briefs/2/$2.md"; vev 11:09 "agent-stop session=S1 agent=$1 type=vid:$3 transcript=-"; }
bc() { vev "$1" "build-cost role=$2 slice=2 step=$3 brief=.vid/briefs/2/$4.md rows=1 rows-passed=1 peak=50 total=90 before-change=12 shell tool=claude model=claude-opus-5-5 effort=high brief-bytes=300${5:+ $5}"; }
# an agent with four kinds and a build-cost
vev 11:00 'agent-start session=S1 agent=U1 type=vid:grader'; vev 11:09 'agent-stop session=S1 agent=U1 type=vid:grader transcript=-'
vev 11:09:01 "usage agent=U1 session=S1 tool=claude model=claude-opus-5-5 effort=high calls=3 $U"
bc 11:10 grader - grader-9 agent=U1
# Codex: a usage record and its events; events alone
for n in 60 61; do printf 'step=S2\ntry=2-builder-%s\nbrief=.vid/briefs/2/builder-%s.md\nmodel=default\neffort=default\n' $n $n > .vid/jobs/2-builder-$n
  printf '{"type":"turn.completed","usage":{"input_tokens":500,"cached_input_tokens":300,"output_tokens":9}}\n' > .vid/jobs/2-builder-$n.events
  vev 11:00 "job-start try=2-builder-$n step=S2"; vev 11:05 "job-exit try=2-builder-$n exit=0 reason=exit"; done
vev 11:05:01 "usage agent=codex:2-builder-60 session=- tool=codex model=default effort=default calls=unknown input=1 cache-read=2 cache-write=0 cache-write-1h=0 output=3 scope=agent"
# two agents linked to one brief
lnk W1 fixer-5 fixer; lnk W2 fixer-5 fixer; bc 11:10 fixer S2 fixer-5
# a reported total
vev 11:11 'build-cost role=grader slice=2 step=- brief=.vid/briefs/2/grader-8.md rows=1 rows-passed=- peak=unknown total=777 before-change=unknown source=agent-tool tool=claude model=unknown effort=unknown brief-bytes=10 agent=G1'
# survived
lnk B1 builder-1 builder; printf 'brief: .vid/briefs/2/builder-1.md\nROW-004 | pass | r2\n' > .vid/briefs/2/builder-1.return.md; bc 11:10 builder S2 builder-1 agent=B1
lnk B2 builder-2 builder; printf 'brief: .vid/briefs/2/builder-2.md\nROW-005 | pass | r2\n' > .vid/briefs/2/builder-2.return.md; bc 11:10 builder S1 builder-2 agent=B2
lnk B3 builder-3 builder; vev 11:09:01 "usage agent=B3 session=S1 tool=claude model=claude-opus-5-5 effort=high calls=1 $U"
lnk B4 builder-4 builder; bc 11:10 builder S2 builder-4 agent=B4; vev 11:12 'continuation-superseded try=2-builder-4'
lnk B7 builder-7 builder; printf 'brief: .vid/briefs/2/builder-7.md\nROW-007 | pass | r2\n' > .vid/briefs/2/builder-7.return.md; bc 11:10 builder S2 builder-7 agent=B7
lnk F6 fixer-6 fixer; printf 'brief: .vid/briefs/2/fixer-6.md\nROW-004 | pass | r2\n' > .vid/briefs/2/fixer-6.return.md; vev 11:09:01 "usage agent=F6 session=S1 tool=claude model=claude-opus-5-5 effort=high calls=1 $U"
vev 11:20 'verdict slice=2 row=ROW-004 result=BREACHED class=product brief=.vid/briefs/2/grader-1.md quoted-at=x'
vev 11:21 'verdict slice=2 row=ROW-005 result=KEPT class=product brief=.vid/briefs/2/grader-1.md quoted-at=x'
vev 11:30 'step-closed step=S2 report=r2'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
ue() { vel "$N" "$1" | grep -F '"kind":"' || fail "no usage entry holds $1"; }
one() { [ "$(vel "$N" "$1" | grep -cF '"kind":"')" = 1 ] || fail "not one usage entry holds $1: $(vel "$N" "$1" | grep -F '"kind":"')"; }
one '{"agent":"U1",'; ue '{"agent":"U1",' | grep -qF '"try":"2-grader-9","tool":"claude","role":"grader","step":null,"slice":"2","stage":"develop","model":"claude-opus-5-5","effort":"high","at":"2026-01-01T11:09:01Z","kind":"kinds","input":10,"cacheRead":100,"cacheWrite":20,"cacheWrite1h":5,"output":7,"total":null,"largestCall":50,"beforeChange":12,"beforeChangeShell":true,"briefBytes":300,"calls":3' || fail "U1's entry: $(ue '{"agent":"U1",')"
one '{"agent":"codex:2-builder-60",'; ue '{"agent":"codex:2-builder-60",' | grep -qF '"kind":"kinds","input":1,"cacheRead":2,"cacheWrite":0,"cacheWrite1h":0,"output":3' || fail "the Codex job's usage record is not its entry"
ue '{"agent":"codex:2-builder-61",' | grep -qF '"model":"default","effort":"default","at":"2026-01-01T11:05:00Z","kind":"kinds","input":200,"cacheRead":300,"cacheWrite":0,"cacheWrite1h":0,"output":9,"total":null' || fail "the Codex job's events: $(ue '{"agent":"codex:2-builder-61",')"
ue '{"agent":null,"try":"1-builder-1",' | grep -qF '"kind":"total","input":null,"cacheRead":null,"cacheWrite":null,"cacheWrite1h":null,"output":null,"total":1' || fail "the older total: $(ue '{"agent":null,"try":"1-builder-1",')"
one '"try":"2-fixer-5",'; ue '"try":"2-fixer-5",' | grep -qF '{"agent":null,' || fail "two agents linked to one brief: $(ue '"try":"2-fixer-5",')"
vel "$N" '{"agent":"W1",' && fail 'W1 has an entry of its own'
ue '{"agent":"G1",' | grep -qF '"kind":"reported",' && ue '{"agent":"G1",' | grep -qF '"total":777' || fail "the reported total: $(ue '{"agent":"G1",')"
sv() { ue "{\"agent\":\"$1\"," | grep -qF "\"survived\":$2,\"why\":$3}" || fail "$1 survived is not $2 ($3): $(ue "{\"agent\":\"$1\",")"; }
sv B1 false '"every row it passed was later broken on review"'; sv B2 true null; sv B3 false '"ended with no hand-back"'
sv B4 false '"superseded by a later try"'; sv B7 true null; sv F6 null null
exit 0
