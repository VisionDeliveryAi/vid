#!/bin/sh
# Purpose: the fixed work package's driver (v0.9.3 §7 case 15) — OWNER-RUN.
# It launches unattended Claude Code sessions (`claude -p`) with the plugin
# at PLUGIN_DIR in a scratch directory, with permission prompts bypassed so
# they can run for hours without a person present (develop starts the
# watcher itself, v0.9.7.0.9), and applies the seeds at their named points. Read it first;
# run it only on a machine where an unattended agent with a container engine
# is acceptable. Nothing here is run by the selftest.
# Usage: PLUGIN_DIR=/path/to/vid sh run-package.sh <scratch-dir>
set -eu
F=$(cd "$(dirname "$0")" && pwd)
PLUGIN_DIR=${PLUGIN_DIR:?the plugin directory at this release}
W=${1:?a new scratch directory}
[ ! -e "$W" ] || { echo "run-package: $W exists — use a new directory" >&2; exit 2; }
mkdir -p "$W"; cp "$F/PRD.md" "$F/ARCHITECTURE.md" "$W/"
grep -q 'STACK: ____' "$F/owner-answers.md" && { echo 'run-package: write the stack into owner-answers.md first' >&2; exit 2; }
LOG="$W.log"; : > "$LOG"
say() { printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" | tee -a "$LOG"; }
session() { # $1=label $2=prompt — one headless session, its JSON result kept
  say "session $1 begins"
  ( cd "$W" && claude -p --plugin-dir "$PLUGIN_DIR" --dangerously-skip-permissions --output-format json "$2" ) > "$W.$1.json" 2>>"$LOG" || say "session $1 exited $?"
  say "session $1 ends"
}
ANS=$(cat "$F/owner-answers.md")
# 1. init, the owner scripted
session init "/vid init — the PRD in this directory is ratified; adopt it. The owner's answers, the only ones you will get (a question they do not answer: decide technically and log it): $ANS"
# 2. the watcher: develop starts it itself (v0.9.7.0.9); its notices are timestamped `observe: notice —` heartbeat lines
# 3. develop, with the seeds: (b) kill after slice 2's first builder commit; the evaluator applies (a), (c), (d) by hand at their points (README), recording each in $LOG
( cd "$W" && claude -p --plugin-dir "$PLUGIN_DIR" --dangerously-skip-permissions --output-format json "/vid develop — the owner's answers for the run: $ANS" > "$W.develop.json" 2>>"$LOG" ) &
DEV=$!
say "develop running as pid $DEV; apply seeds (a), (c), (d) by hand at their points; this script kills develop at seed (b)"
until grep -q '^slice-open slice=2 ' "$W/.vid/metrics-events" 2>/dev/null && [ "$(git -C "$W" log --oneline "$(sed -n 's/^slice-open slice=2 sha=\([^ ]*\).*/\1/p' "$W/.vid/metrics-events" | head -n 1)..HEAD" 2>/dev/null | wc -l)" -ge 1 ]; do sleep 30; kill -0 "$DEV" 2>/dev/null || break; done
if kill -0 "$DEV" 2>/dev/null; then pkill -P "$DEV" 2>/dev/null || true; kill "$DEV" 2>/dev/null || true; say "seed (b): develop killed mid-slice 2"; fi
say 'waiting for the watcher'"'"'s notice, then a fresh session resumes'
NB=$(grep -c '| observe: notice — ' "$W/.vid/HEARTBEAT.md" 2>/dev/null || true)
until [ "$(grep -c '| observe: notice — ' "$W/.vid/HEARTBEAT.md" 2>/dev/null || true)" -gt "${NB:-0}" ]; do sleep 30; done
say "notice: $(grep '| observe: notice — ' "$W/.vid/HEARTBEAT.md" | tail -n 1)"
session resume "/vid develop — you are a fresh session taking over a run whose session died. Resume from records: run sh checks/observe.sh resume first, read .vid/RUN-STATE.md, and continue the run to completion. The owner's answers: $ANS"
kill "$(sed -n 1p "$W/.vid/observer.pid" 2>/dev/null || echo 0)" 2>/dev/null || true   # the watcher loop, if the run did not complete
say 'done — fill counts.md from the records under the scratch directory and this log'
