#!/bin/sh
# Purpose: selftest case — needs attention, each dated, current or past (v0.26.10.6 spec R5). The viewer fixture with
# its open question (Q2), and planted: a `died` followed by a `run` (past) and a later `died` (current); an
# `agent-death` (never current); the watcher's notices — one tick holding one `agentq` key and its one line (current,
# linked to its agent), one tick holding two `agentq` keys and two lines (both current, neither linked), a quiet notice
# no key stands for (past), a progress notice (left out) and a standing `qlist` key's notice (current); a `stall`
# whose operation is still past its time (current) and one done (past); a recovery standing; a teardown failed whose
# holder remains (current, its slot) and one gone (past); hand-backs with no acceptance whose step is open (current)
# and closed (past); and RUN-STATE's `run: waiting`. Convicts unless each item's kind, current and links are as
# recorded and the list runs newest first by its time, nulls last. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-attention: $*" >&2; exit 1; }
view_project "$T/repo"
sed 's/^run: active$/run: waiting on Q2/' .vid/RUN-STATE.md > .vid/rs.x && mv .vid/rs.x .vid/RUN-STATE.md
vev 11:11 'died reason=server_error session=S1'; vev 11:12 'run state=active'; vev 11:16 'run state=waiting'; vev 11:30 'died reason=overloaded_error session=S1'
vev 11:13 'agent-death slice=1 builder-2 (S1) lost to a network error'
vev 11:14 'stall op=prev elapsed=100 envelope=60'; vev 11:14 'stall op=gone elapsed=90 envelope=60'; mkdir -p .vid/watchdog; : > .vid/watchdog/prev
mkdir -p .vid/jobs; printf 'step=S2\ntry=1-builder-30\nbrief=.vid/briefs/1/builder-30.md\n' > .vid/jobs/1-builder-30
vev 11:00 'job-start try=1-builder-30 step=S2'; vev 11:15 'job-recovery-required try=1-builder-30 reason=no-identity'
vev 11:15 'teardown-failed request=20260101T110000Z-aaaa project=vid-s1-x'; vev 11:15 'teardown-failed request=- project=vid-s2-y'
mkdir -p .vid/runs/R1; printf 'pid=1\nstart=1767265200\nkind=scoped\nworktree=/w/agent-q1\nslot=1\nproject=vid-s1-x\n' > .vid/runs/R1/holder
mkdir -p .vid/briefs/1; printf 'role: fixer    slice: 1    step: S2\n' > .vid/briefs/1/fixer-7.md; printf 'role: fixer    slice: 1    step: S1\n' > .vid/briefs/1/fixer-8.md
printf 'brief: .vid/briefs/1/fixer-7.md\nROW-004 | pass | r2\n' > .vid/briefs/1/fixer-7.return.md; printf 'brief: .vid/briefs/1/fixer-8.md\nROW-001 | pass | r1\n' > .vid/briefs/1/fixer-8.return.md
for a in Q1 Q2 Q3; do vev 11:00 "agent-start session=S1 agent=$a type=vid:fixer"; done
{ printf '# Heartbeat\n'
  printf -- '- 2026-01-01T10:30:00Z | observe: notice — ViD: the build has gone quiet for 30 min without saying why\n'
  printf -- '- 2026-01-01T11:40:30Z | observe: run activity 30s ago (events) · run: active\n'
  printf -- '- 2026-01-01T11:41:00Z | observe: notice — ViD: an agent has had no new step for 40 min: Fixer 1. It may be stuck.\n'
  printf -- '- 2026-01-01T11:42:00Z | observe: notice — ViD progress — Toy: 3 of 7 rows passing\n'
  printf -- '- 2026-01-01T11:50:00Z | observe: run activity 10s ago (events) · run: active\n'
  printf -- '- 2026-01-01T11:55:10Z | observe: run activity 10s ago (events) · run: active\n'
  printf -- '- 2026-01-01T11:56:00Z | observe: notice — ViD: an agent has had no new step for 55 min: Fixer 2. It may be stuck.\n'
  printf -- '- 2026-01-01T11:56:01Z | observe: notice — ViD: an agent has had no new step for 55 min: Fixer 3. It may be stuck.\n'
  printf -- '- 2026-01-01T12:05:20Z | observe: run activity 10s ago (events) · run: active\n'
  printf -- "- 2026-01-01T12:06:00Z | observe: notice — ViD: the build's list of questions to you can't be read.\n"; } > .vid/HEARTBEAT.md
printf 'notified.agentq.Q1.1 1767267600\nnotified.agentq.Q2.1 1767268500\nnotified.agentq.Q3.1 1767268500\nnotified.progress.x 1767269100\nnotified.qlist.1.1 1767269100\nnotified.quiet.5 \ntick 1767269100 /h\n' > .vid/observer.state
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
A=$(vdata "$N" | awk '/^"attention":\[/ { on = 1 } on { print } on && /\],$/ { exit }')
it() { printf '%s\n' "$A" | grep -F -- "$1" || fail "no attention item holds: $1"; }
cu() { it "$1" | grep -qF "\"current\":$2" || fail "not current=$2: $(it "$1")"; }
it '"kind":"question","at":"2026-01-01","current":true,"text":"Q2 · asked 2026-01-01' | grep -qF '"question":"Q2"' || fail 'the question is not linked to Q2'
cu '"kind":"run-died","at":"2026-01-01T11:11:00Z"' false; cu '"kind":"run-died","at":"2026-01-01T11:30:00Z"' true
cu '"kind":"agent-died"' false; it '"kind":"agent-died"' | grep -qF '"text":"slice=1 builder-2 (S1) lost to a network error"' || fail 'the agent death is not as written'
cu 'Fixer 1.' true; it 'Fixer 1.' | grep -qF '"kind":"quiet"' && it 'Fixer 1.' | grep -qF '"agent":"Q1"' || fail "the one-key tick's line is not linked to Q1: $(it 'Fixer 1.')"
cu 'Fixer 2.' true; cu 'Fixer 3.' true
it 'Fixer 2.' | grep -qF '"agent":null' && it 'Fixer 3.' | grep -qF '"agent":null' || fail 'a line of the two-key tick was linked'
cu 'has gone quiet for 30 min' false; it 'has gone quiet for 30 min' | grep -qF '"kind":"quiet"' || fail 'the quiet notice is not quiet'
printf '%s\n' "$A" | grep -qF 'ViD progress' && fail 'a progress notice is listed'
cu "list of questions" true; it "list of questions" | grep -qF '"kind":"notice"' || fail 'the qlist notice is not a notice'
cu '(prev, 100 s of 60 s)' true; cu '(gone, 90 s of 60 s)' false
it '"kind":"stuck"' | grep -qF '"text":"an operation ran past its time limit (prev, 100 s of 60 s)"' || fail 'the stuck words'
cu '"kind":"needs-recovery"' true
cu '(vid-s1-x)' true; it '(vid-s1-x)' | grep -qF '"ticket":"20260101T110000Z-aaaa","slot":"1"' || fail "the environment left: $(it '(vid-s1-x)')"; cu '(vid-s2-y)' false
cu 'fixer-7.return.md' true; cu 'fixer-8.return.md' false; it 'fixer-7.return.md' | grep -qF '"kind":"no-acceptance","at":null' || fail 'no-acceptance is dated'
cu '"kind":"run-state"' true; it '"kind":"run-state"' | grep -qF '"at":"2026-01-01T11:16:00Z","current":true,"text":"run: waiting on Q2"' || fail "the run state: $(it '"kind":"run-state"')"
# newest first by at, nulls last
printf '%s\n' "$A" | grep -o '"at":[^,]*' | sed 's/"at"://' | awk '{ if ($0 == "null") n = 1; else if (n) bad = 1; else if (p != "" && $0 > p) bad = 1; p = $0 } END { exit bad }' || fail "the list is not newest first, nulls last: $(printf '%s\n' "$A" | grep -o '"at":[^,]*' | tr '\n' ' ')"
exit 0
