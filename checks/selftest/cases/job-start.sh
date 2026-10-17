#!/bin/sh
# Purpose: selftest case — a Codex builder's job record and worktree (v0.9.7.1 spec 3.9, R9). The job fixture.
# Convicts unless `start --brief` refuses an unchecked brief; writes .vid/jobs/1-builder-1 naming the run, step,
# try, brief and hash, worktree, plugin root and version, model, effort and the return path; makes the worktree a
# detached `git worktree` at the brief's quoted-at whose .vid/home names the run's home; records `job-start
# try=1-builder-1 step=S1`; and refuses the same try twice. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-start: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
cp "$B" "$T/copy.md"; mkdir -p .vid/briefs/9; cp "$B" .vid/briefs/9/builder-1.md
if sh checks/job.sh start --brief .vid/briefs/9/builder-1.md > "$T/out" 2>&1; then fail 'an unchecked brief started a job'; fi
sh checks/job.sh start --brief "$B" > "$T/out" 2>&1 || fail 'start refused'
J=.vid/jobs/1-builder-1; [ -f "$J" ] || fail 'no job record'
for k in run step try brief brief-hash quoted-at worktree plugin version model effort return; do grep -q "^$k=" "$J" || fail "the record lacks $k="; done
grep -qx 'version=9.9.9' "$J" && grep -qx 'step=S1' "$J" || fail 'the record'"'"'s version or step is wrong'
WT=$(sed -n 's/^worktree=//p' "$J"); [ -d "$WT" ] || fail 'no worktree'
[ "$(git -C "$WT" rev-parse HEAD)" = "$(sed -n 's/^quoted-at: //p' "$B")" ] || fail 'the worktree is not at quoted-at'
git -C "$WT" symbolic-ref -q HEAD > /dev/null && fail 'the worktree HEAD is not detached'
[ "$(cat "$WT/.vid/home")" = "$(pwd -P)" ] || fail 'the worktree'"'"'s .vid/home does not name the home'
grep -q '^job-start try=1-builder-1 step=S1 ' .vid/metrics-events || fail 'no job-start event'
if sh checks/job.sh start --brief "$B" > "$T/out" 2>&1; then fail 'the same try started twice'; fi
grep -q 'never launched twice' "$T/out" || fail 'the refusal does not say why'
exit 0
