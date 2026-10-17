#!/bin/sh
# Purpose: ViD event helper (v0.9.5 3.11, R11) — the one way a session
# writes an event. Appends its argument to .vid/metrics-events as one line
# ending ` at=<UTC>` (YYYY-MM-DDTHH:MM:SSZ), creating .vid/ when it is
# missing. A reader takes a line's LAST `at=` token, since a free-text event
# may carry the string itself. The skills name this helper at every event
# instruction; the skills that can run before a project's checks/ exists
# (vid-create-prd, vid-init's own start, vid-design and vid-test-inventory)
# call the plugin's copy, sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh". The
# record contract is RECORDS.md (records: 5 since v0.9.7.0.1, checks/records-version).
# v0.9.6.2 (3.1, R1): the line goes to the run's HOME's .vid/metrics-events
# — this worktree's top level when it holds .vid/RUN-STATE.md, else the path
# its .vid/home names (when that path holds a run), else this worktree's top
# level; outside a repository, this directory — so a builder worktree's
# events land where the home's readers look. On a line starting `stage `
# that carries `state=start`, the run id (checks/run.sh id beside this
# script: .vid/run made or renewed) is added as ` run=<id>` before the
# ` at=`, which stays the last token.
# Refuses an empty event and one spanning lines (the second line would carry
# no time). Usage: sh checks/event.sh '<type> <field>=<value> …'
set -eu
L=${1:-}
[ $# -eq 1 ] && [ -n "$L" ] || { echo "ViD event: usage — sh checks/event.sh '<type> <field>=<value> …' (one quoted argument)" >&2; exit 2; }
case "$L" in *'
'*) echo 'ViD event: refused — an event is one line; this one spans several.' >&2; exit 2 ;; esac
TOP=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
H=$TOP
if [ ! -f "$TOP/.vid/RUN-STATE.md" ] && [ -f "$TOP/.vid/home" ]; then
  _h=$(sed -n 1p "$TOP/.vid/home")
  if [ -n "$_h" ] && [ -f "$_h/.vid/RUN-STATE.md" ]; then H=$_h; fi
fi
# v0.9.7.0.1 (3.1, R4): the plan.sh beside this script resolves the home
# (home-of); missing, older, or any exit but 0 keeps the lookup above
_pl="$(dirname "$0")/plan.sh"
if [ -f "$_pl" ]; then
  _prc=0; _ph=$(sh "$_pl" home-of 2>/dev/null) || _prc=$?
  if [ "$_prc" -eq 0 ] && [ -n "$_ph" ] && [ -d "$_ph" ]; then H=$_ph
  elif [ "$_prc" -eq 3 ]; then echo "ViD event: note — $_ph; written here, at $H." >&2; fi
fi
mkdir -p "$H/.vid"
RUN=''
case "$L" in
  'stage '*)
    if printf '%s\n' "$L" | tr ' ' '\n' | grep -qx 'state=start'; then
      _r="$(dirname "$0")/run.sh"
      if [ -f "$_r" ]; then RUN=$(cd "$H" && sh "$_r" id 2>/dev/null || true); fi
    fi ;;
esac
if [ -n "$RUN" ]; then L="$L run=$RUN"; fi
printf '%s at=%s\n' "$L" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$H/.vid/metrics-events"
