# Purpose: selftest fixture — shared helpers for the observer's notice cases
# (v0.9.5 spec 3.3, 3.5). Sourced by a case after it has made and entered
# its scratch directory $T: a toy repository whose clocks are months old
# (one commit, one session heartbeat line), the observer and its readers
# copied in. v0.9.7.0.9 (3.8, R13): nothing is sent — a notice is an
# `observe: notice — <text>` heartbeat line; after each tick, $T/notify.log
# is rebuilt from those lines, every worktree's, one line per notice.
# Env: CHECKS, T.
utc() { awk -v e="$1" 'BEGIN { d = int(e / 86400); s = e - d * 86400; z = d + 719468; era = int(z / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365); y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
  mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); if (m <= 2) y++
  printf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", y, m, dd, int(s / 3600), int((s % 3600) / 60), s % 60 }'; }
ago() { utc $(( $(date +%s) - $1 )); }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q
mkdir -p checks .vid
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/brief.sh" "$CHECKS/prd.sh" "$CHECKS/lawfiles" checks/
export VID_OBSERVE_INTERVAL=60 VID_PROBE_BOUND=5
printf '.vid/\n' > .gitignore
OLD='2026-01-01T00:00:00+0000'
git add -A   # the old dates on git itself, never on the function g: an assignment before a function call can outlive it
GIT_COMMITTER_DATE=$OLD GIT_AUTHOR_DATE=$OLD git -c user.email=vid@selftest -c user.name=vid commit -qm root
# rs <run value> [question lines, newline-separated] [questions: key] — RUN-STATE in the 0.9.5 form
rs() {
  _k=${3:-}; if [ -z "$_k" ]; then _n=$(printf '%s' "${2:-}" | grep -c '^- Q' || true); if [ "$_n" -gt 0 ]; then _k="$_n open · next Q9"; else _k='- · next Q9'; fi; fi
  { printf 'run: %s\nsession: S1\nquestions: %s\nslice: 3 open    since: 2026-01-01T00:00:00Z    commit: x\nmodules: app/feed\nclaims: -\nreceipt: none    briefs: -\nheld: -\n\n## Slice 3 — the plan\n\nThe plan, as prose.\n\n## Open product questions\n\n<!-- one line per question -->\n' "$1" "$_k"
    [ -n "${2:-}" ] && printf '%s\n' "$2"
    printf '\n## Rows under work\n\nnone\n'; } > .vid/RUN-STATE.md
}
reset() { rm -rf .vid/watchdog .vid/NUDGE .vid/observer.state .vid/ledger.lock .vid/hook-times "$T/notify.log"; printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: the session last spoke months ago\n' > .vid/HEARTBEAT.md; : > .vid/metrics-events; }
ev() { printf '%s at=%s\n' "$1" "$2" >> .vid/metrics-events; }
hb() { printf -- '- %s | note: %s\n' "$1" "$2" >> .vid/HEARTBEAT.md; }
nlog() { git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | while IFS= read -r _w; do [ -f "$_w/.vid/HEARTBEAT.md" ] && sed -n 's/^- [^|]* | observe: notice — //p' "$_w/.vid/HEARTBEAT.md"; done > "$T/notify.log"; }
tick() { sh checks/observe.sh > "$T/tick.out" 2>&1; nlog; }
nnote() { if [ -f "$T/notify.log" ]; then grep -c "${1:-.}" "$T/notify.log" || true; else echo 0; fi; }
fail() { echo "${CASE:-observer}: $*" >&2; cat "$T/tick.out" >&2 2>/dev/null; cat "$T/notify.log" >&2 2>/dev/null; exit 1; }
