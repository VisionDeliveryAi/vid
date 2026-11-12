#!/bin/sh
# Purpose: selftest case — the status's plan-change count under either date (0.26.10.28.1, 9.1 R7, F4). TW's toy, the last
# update just after its own plan events and two plan changes after it: `queue.sh status` counts both with only GNU date on the path (a stub that
# refuses `-j`, as on Linux, WSL or Git Bash) and with only BSD date (a stub that refuses `-d`, as on macOS). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-date-forms: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
RD=$(command -v date)
# each stub refuses one form and serves the other through the real date, whichever kind it is
mkdir -p "$T/gnu" "$T/bsd"
cat > "$T/gnu/date" <<E
#!/bin/sh
for a; do [ "\$a" = -j ] && exit 1; done
if [ "\${1:-}" = -u ] && [ "\${2:-}" = -d ]; then "$RD" -u -d "\$3" "\$4" 2>/dev/null || "$RD" -u -j -f '%Y-%m-%dT%H:%M:%SZ' "\$3" "\$4"; exit; fi
exec "$RD" "\$@"
E
cat > "$T/bsd/date" <<E
#!/bin/sh
for a; do [ "\$a" = -d ] && exit 1; done
if [ "\${1:-}" = -u ] && [ "\${2:-}" = -j ]; then "$RD" -u -j -f "\$4" "\$5" "\$6" 2>/dev/null || "$RD" -u -d "\$5" "\$6"; exit; fi
exec "$RD" "\$@"
E
chmod +x "$T/gnu/date" "$T/bsd/date"
[ "$(PATH="$T/gnu:$PATH" date -u -d 2026-11-11T10:00:00Z +%s)" = "$(PATH="$T/bsd:$PATH" date -u -j -f '%Y-%m-%dT%H:%M:%SZ' 2026-11-11T10:00:00Z +%s)" ] || fail 'the stubs disagree (the case is wrong)'
tw_toy "$T/toy"; mkdir -p .vid/decide/queue
# the last update just after the toy's own plan events, the two changes after it
now=$(date +%s); echo $((now + 5)) > .vid/decide/queue/updated
A=$(date -u -r $((now + 10)) '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$((now + 10))" '+%Y-%m-%dT%H:%M:%SZ')
printf 'plan-change kind=rows at=%s\nplan-change kind=other at=%s\n' "$A" "$A" >> .vid/metrics-events
for k in gnu bsd; do
  PATH="$T/$k:$PATH" VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail "status failed with $k date"
  grep -q '^plan changes since the last update: 2' "$T/out" || fail "with only $k date the plan changes are not counted: $(grep '^plan changes' "$T/out")"
done
exit 0
