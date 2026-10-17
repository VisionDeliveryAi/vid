#!/bin/sh
# Purpose: selftest case — recovery is the handoff protocol, named (v0.9.3
# spec 3.12, R16; §7 case 11). A toy repository killed mid-slice:
# RUN-STATE open with modules and claims, a live brief, a declared
# operation, an uncommitted path, a stale lock. Convicts unless `sh
# checks/observe.sh resume` names each of them from records alone, and,
# after the completion (RUN-STATE `run: complete`, the slice closed, the
# brief retired, the lock removed, the tree committed), says nothing is
# open; and (v0.9.5 3.5, §7 case 5) prints the whole `run:` value,
# `session:`, the open questions and a standing death, and no death once a
# newer `run state` event exists. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks .vid/briefs/7 app
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
printf '# Purpose: toy\n' > app/main.py
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
printf 'role: builder    slice: 7\nquoted-at: x\n' > .vid/briefs/7/builder-1.md
printf 'run: active\nslice: 7 open    since: 2026-09-23T02:10:00Z    commit: abc123\nmodules: app/feed app/search\nclaims: ROW-201 ROW-202\nreceipt: none    briefs: .vid/briefs/7/builder-1.md\nheld: ROW-044\n\nSlice 7: the feed chain end to end.\n' > .vid/RUN-STATE.md
mkdir -p .vid/ledger.lock; printf '99999999\n2026-09-23 03:00:00\n%s\n' "$(( $(date +%s) - 3000 ))" > .vid/ledger.lock/holder
mkdir -p .vid/runs/20260923T030000Z-99999998; printf 'pid=99999998\nstart=%s\nkind=scoped\n' "$(( $(date +%s) - 2000 ))" > .vid/runs/20260923T030000Z-99999998/holder   # v0.9.6: a dead gated run folder
sh checks/watchdog.sh declare builder-7 5400 'kill -0 31337 # builder 7' 31337 >/dev/null
printf '# Purpose: toy — half-written\n' >> app/main.py
OUT=$(sh checks/observe.sh resume)
fail() { echo "resume: $*" >&2; printf '%s\n' "$OUT" >&2; exit 1; }
for want in 'resume: run: active' 'resume: slice 7 open' 'resume: modules: app/feed app/search' 'resume: claims: ROW-201 ROW-202' 'resume: held (recorded): ROW-044' 'resume: live brief .vid/briefs/7/builder-1.md' 'resume: declared operation builder-7' 'resume: uncommitted app/main.py' 'resume: STALE lock .vid/ledger.lock — pid 99999999 is gone' 'resume: STALE run folder .vid/runs/20260923T030000Z-99999998 — pid 99999998 is gone' 'resume: receipt: none current at HEAD'; do
  printf '%s\n' "$OUT" | grep -qF "$want" || fail "missing: $want"
done
printf '%s\n' "$OUT" | grep -q 'nothing open' && fail 'a killed run reads as nothing open'
# after the completion
git add app/main.py && git -c user.email=vid@selftest -c user.name=vid commit -qm 'slice 7'
rm -rf .vid/ledger.lock .vid/briefs .vid/runs; sh checks/watchdog.sh done builder-7 >/dev/null
printf 'run: complete\nslice: 7 closed    since: 2026-09-23T02:10:00Z    commit: def456\nmodules: -\nclaims: -\nreceipt: none    briefs: -\nheld: -\n\nComplete.\n' > .vid/RUN-STATE.md
OUT=$(sh checks/observe.sh resume)
printf '%s\n' "$OUT" | grep -qx 'resume: nothing open — run: complete' || fail 'a completed run does not read as nothing open'
# v0.9.5 (3.5; §7 case 5): the whole run: value, session:, the open questions, a standing death
printf 'run: stopped the database will not start\nsession: S7\nquestions: 1 open · next Q2\nslice: 8 open    since: 2026-09-23T02:10:00Z    commit: def456\nmodules: app/feed\nclaims: -\nreceipt: none    briefs: -\nheld: -\n\n## Open product questions\n\n- Q1 · asked 2026-09-23T03:00:00Z · gates ROW-201 · Is the export weekly?\n' > .vid/RUN-STATE.md
printf 'died reason=overloaded session=S7 at=2026-09-23T04:00:00Z\n' >> .vid/metrics-events
OUT=$(sh checks/observe.sh resume)
for want in 'resume: run: stopped the database will not start' 'resume: session: S7' 'resume: open question Q1 · asked 2026-09-23T03:00:00Z · gates ROW-201 · Is the export weekly?' 'resume: died — session S7 at 2026-09-23T04:00:00Z, reason overloaded'; do
  printf '%s\n' "$OUT" | grep -qF "$want" || fail "missing: $want"
done
printf 'run state=active at=2026-09-23T05:00:00Z\n' >> .vid/metrics-events
sh checks/observe.sh resume | grep -q 'resume: died' && fail 'a death with a newer run state event still reads as standing'
# v0.9.7.0.6 (§6 A-5): the agents
TR="$T/tr"; mkdir -p "$TR/S7/subagents"
printf '{"timestamp":"%s"}\n' "$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')" > "$TR/S7/subagents/agent-ab1.jsonl"
printf '{"description":"Build slice 8"}\n' > "$TR/S7/subagents/agent-ab1.meta.json"
printf 'agent-start session=S7 agent=ab1 type=general-purpose transcript=%s/S7.jsonl at=2026-09-23T05:10:00Z\n' "$TR" >> .vid/metrics-events
printf 'agent-start session=S7 agent=ab2 type=general-purpose transcript=%s/S7.jsonl at=2026-09-23T05:10:00Z\nagent-stop session=S7 agent=ab2 type=general-purpose transcript=- at=2026-09-23T05:20:00Z\n' "$TR" >> .vid/metrics-events
OUT=$(sh checks/observe.sh resume)
printf '%s\n' "$OUT" | grep -qE '^resume: agent ab1 working [0-9]+s "Build slice 8"$' || fail 'the open agent is not printed'
printf '%s\n' "$OUT" | grep -q 'agent ab2' && fail 'a finished agent is printed'
exit 0
