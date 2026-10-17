#!/bin/sh
# Purpose: selftest case — a Codex return's brief line (v0.9.8.1 R16, F-9). The job fixture: the bootstrap gives the
# return's brief line verbatim (`brief: <the brief's path>`); a Codex return whose brief line is the bare file name
# (`brief: builder-1.md`) is taken as the run's one brief of that name and its build-cost records the full path; with
# a second brief of the same name in another slice the bare name is refused, naming both. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "return-bare-brief-header: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
B=${B#./}
sh checks/job.sh start --brief "$B" > "$T/out" 2>&1 || fail 'start refused'
RET=$(sed -n 's/^return: //p' "$B")
FAKE_CODEX=ok FAKE_BARE=1 FAKE_BOOT="$T/boot" sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1 || fail 'run failed'
grep -qF "Its brief line is, verbatim: brief: $B" "$T/boot" || fail "the bootstrap does not give the brief line verbatim: $(grep -i 'brief line' "$T/boot")"
grep -qx "brief: ${B##*/}" "$RET" || fail 'the fixture did not write a bare brief line'
# a second brief of that name elsewhere: refused, both named
mkdir -p .vid/briefs/9; cp "$B" ".vid/briefs/9/${B##*/}"
if sh checks/brief.sh return "$RET" --agent codex:1-builder-1 > "$T/out" 2>&1; then fail 'a bare name matching two briefs was taken'; fi
grep -q 'names more than one brief of the run' "$T/out" || fail 'the refusal does not say the name is ambiguous'
rm -rf .vid/briefs/9
sh checks/brief.sh return "$RET" --agent codex:1-builder-1 > "$T/out" 2>&1 || fail 'the bare brief name was refused'
grep -q "^build-cost role=builder .* brief=$B rows=" .vid/metrics-events || fail "build-cost does not record the brief's path: $(grep '^build-cost' .vid/metrics-events)"
exit 0
