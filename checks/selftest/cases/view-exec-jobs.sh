#!/bin/sh
# Purpose: selftest case — every Codex job (v0.26.10.6 spec R2). The viewer fixture with eight planted jobs: open
# (working), a recovery standing (needs-recovery), exit 1 with no return file (died), a return accepted (returned), a
# return with no acceptance (unaccepted), stopped at Codex's limit and stopped (both ended, each its detail), and a
# recovery later cleaned. Convicts unless each is one entry `codex:<try>`, tool codex, linked, with its job record's
# model and effort, one run from job-start to job-exit or job-stop (open with neither), and the state above. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-jobs: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/jobs .vid/briefs/1
for n in 11 12 13 14 15 16 17 18; do
  printf 'step=S2\ntry=1-builder-%s\nbrief=.vid/briefs/1/builder-%s.md\nmodel=gpt-x\neffort=high\n' $n $n > .vid/jobs/1-builder-$n
  vev 11:00 "job-start try=1-builder-$n step=S2"
done
vev 11:01 'job-recovery-required try=1-builder-12 reason=no-identity'
vev 11:02 'job-exit try=1-builder-13 exit=1 reason=exit'
vev 11:03 'job-exit try=1-builder-14 exit=0 reason=exit'; printf 'brief: .vid/briefs/1/builder-14.md\nROW-004 | pass | r2\n' > .vid/briefs/1/builder-14.return.md
vev 11:04 'agent-returned role=builder n=14 try=1-builder-14'
vev 11:03 'job-exit try=1-builder-15 exit=0 reason=exit'; printf 'brief: .vid/briefs/1/builder-15.md\nROW-004 | not | none | not done\n' > .vid/briefs/1/builder-15.return.md
vev 11:05 'job-exit try=1-builder-16 exit=1 reason=codex-limit'
vev 11:06 'job-exit try=1-builder-17 exit=143 reason=stopped'; vev 11:07 'job-stop try=1-builder-17 saved=yes'
vev 11:06 'job-recovery-required try=1-builder-18 reason=group-remains'; vev 11:08 'job-cleaned try=1-builder-18'; vev 11:09 'job-stop try=1-builder-18 saved=no'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
jb() { vel "$N" "{\"id\":\"codex:1-builder-$1\",\"tool\":\"codex\",\"session\":null,\"type\":null,\"started\":\"2026-01-01T11:00:00Z\",\"role\":\"builder\",\"try\":\"1-builder-$1\",\"step\":\"S2\",\"slice\":\"1\",\"brief\":\".vid/briefs/1/builder-$1.md\""; }
st() { jb "$1" | grep -qF "\"state\":\"$2\",\"stateDetail\":$3" || fail "job $1 is not $2 ($3): $(jb "$1")"; }
for n in 11 12 13 14 15 16 17 18; do [ "$(jb $n | wc -l | tr -d ' ')" = 1 ] || fail "job $n is not one entry"; jb $n | grep -qF '"model":"gpt-x","effort":"high","linked":true' || fail "job $n is not linked with its record's model and effort: $(jb $n)"; done
jb 11 | grep -qF '"runs":[{"started":"2026-01-01T11:00:00Z","ended":null,"endedBy":null}]' || fail "the open job's run: $(jb 11)"
st 11 working null; st 12 needs-recovery null; st 13 died null; st 14 returned null; st 15 unaccepted null
st 16 ended '"stopped at Codex'"'"'s limit"'; st 17 ended '"stopped"'; st 18 ended null
jb 13 | grep -qF '"runs":[{"started":"2026-01-01T11:00:00Z","ended":"2026-01-01T11:02:00Z","endedBy":"job-exit"}],"seconds":120' || fail "the died job's run: $(jb 13)"
jb 18 | grep -qF '"endedBy":"job-stop"' || fail "a job stopped with no exit is not ended by job-stop: $(jb 18)"
vdata "$N" | grep -o '"agentsOpen":\[[^]]*\]' | grep -qF 'Codex builder 1-builder-11 · S2' || fail 'agents now does not name the open job'
exit 0
