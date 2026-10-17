#!/bin/sh
# Purpose: selftest case — the observer reads Codex builders' jobs and the pause (v0.9.7.1 spec 3.9, R9). The
# observer fixture: a toy run whose clocks are months old, `run: active`. Convicts unless: a job whose group
# leader is alive with its recorded start time and whose events file is fresh holds the quiet notice, as a working
# agent does; the same job with a stale events file does not; a job whose process is gone with no exit= gives one
# notice naming it; while builder-tool=paused the owner's plain line ("Codex has run out of allowance (resets 3:05
# PM). Builders are paused. Say 'use Claude for builders' …") is noticed once; and `resume` lists the open job.
# Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap 'rm -rf "$T"; [ -n "$P" ] && kill "$P" 2>/dev/null; true' EXIT
cd "$T"; CASE=job-observe
. "$CHECKS/selftest/fixtures/observer-lib.sh"
cp "$CHECKS/job.sh" "$CHECKS/event.sh" checks/
Q='gone quiet'
sleep 300 & P=$!
reset; rs active
mkdir -p .vid/jobs; printf 'try=3-builder-9\nworktree=%s/wt\nreturn=%s/r.md\npgid=%s\npid-start=%s\n' "$T" "$T" "$P" "$(ps -o lstart= -p $P | sed 's/^ *//')" > .vid/jobs/3-builder-9
printf '{"type":"turn.completed"}\n' > .vid/jobs/3-builder-9.events
tick; [ "$(nnote "$Q")" -eq 0 ] || fail 'a live job with fresh events did not hold the quiet notice'
touch -t 202601010000 .vid/jobs/3-builder-9.events
reset; rs active
mkdir -p .vid/jobs; printf 'try=3-builder-9\nworktree=%s/wt\nreturn=%s/r.md\npgid=%s\npid-start=%s\n' "$T" "$T" "$P" "$(ps -o lstart= -p $P | sed 's/^ *//')" > .vid/jobs/3-builder-9
printf '{"type":"turn.completed"}\n' > .vid/jobs/3-builder-9.events; touch -t 202601010000 .vid/jobs/3-builder-9.events
tick; [ "$(nnote "$Q")" -eq 1 ] || fail 'a job with stale events held the quiet notice'
sh checks/observe.sh resume > "$T/res" 2>&1; grep -q '^resume: job 3-builder-9: process alive' "$T/res" || fail "resume does not list the open job: $(grep job "$T/res")"
kill "$P"; wait "$P" 2>/dev/null || true; P=''
tick; [ "$(nnote 'Codex builder (3-builder-9) stopped without a result')" -eq 1 ] || fail 'a dead job is not told'
tick; [ "$(nnote 'Codex builder (3-builder-9)')" -eq 1 ] || fail 'the dead job notice repeated'
printf 'builder-tool=paused\n' >> .vid/budget; ev 'builder-tool paused reason=codex-limit reset=3:05_PM' "$(ago 10)"
tick; [ "$(nnote "Codex has run out of allowance (resets 3:05 PM). Builders are paused. Say 'use Claude for builders' to continue on Claude, or 'wait for Codex' to resume when it resets.")" -eq 1 ] || fail 'the pause line is not noticed as written'
tick; [ "$(nnote 'Builders are paused')" -eq 1 ] || fail 'the pause notice repeated'
exit 0
