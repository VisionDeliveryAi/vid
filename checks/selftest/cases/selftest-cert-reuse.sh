#!/bin/sh
# Purpose: selftest case — the self-test certificate is shared by every checkout (v0.9.7.3 spec 3.6, R6). Under the
# real hook: a law commit's full pass publishes <git common dir>/vid-selftest/<key> reading `pass <key>`; a law
# commit in another worktree of the repository, its key the same, skips the shipped cases on it; a failed run and an
# interrupted one (TERM mid-run) publish nothing, and the next law commit runs the suite. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/cert.sh"
fail() { echo "selftest-cert-reuse: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ct_repo "$T/main"
ct_row 2; ct_law 'first'
[ "$(ct_runs)" = 1 ] || fail 'the first law commit did not run the suite'
C=$(ct_cert); K=$(ls "$C" | grep -v '^\.'); [ "$(printf '%s\n' "$K" | grep -c .)" = 1 ] || fail 'not one certificate'
[ "$(cat "$C/$K")" = "pass $K" ] || fail 'the certificate does not read pass <key>'
[ ! -e "$(git rev-parse --git-path vid-memo)/selftest" ] || fail 'the per-worktree memo is still written'
git worktree add -q "$T/wt" -b other 2>/dev/null; cd "$T/wt"; mkdir -p .ran .fail
ct_row 3; ct_law 'from another worktree'
grep -q "selftest: ViD's shipped checks unchanged" "$T/out" || fail 'another worktree did not use the shared certificate'
[ "$(ct_runs)" = 1 ] || fail 'another worktree ran the shipped case'
# a failed run publishes nothing
cd "$T/main"; rm -rf "$C"; printf 'exit 1\n' > "$T/hook-in.sh"; ct_row 4
if sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail 'a failing suite passed'; fi
[ -z "$(ls "$C" 2>/dev/null)" ] || fail 'a failed run published a certificate'
# an interrupted run publishes nothing
printf 'touch "%s/in-run"; while [ -f "%s/hold" ]; do sleep 1; done\n' "$T" "$T" > "$T/hook-in.sh"; : > "$T/hold"; rm -f "$T/in-run"
sh checks/hooks/pre-commit > "$T/out" 2>&1 & HP=$!
i=0; until [ -f "$T/in-run" ] || [ "$i" -ge 60 ]; do sleep 1; i=$((i + 1)); done
kill -TERM "$HP" 2>/dev/null; rm -f "$T/hold"; wait "$HP" 2>/dev/null || true
[ -z "$(ls "$C" 2>/dev/null)" ] || fail 'an interrupted run published a certificate'
rm -f "$T/hook-in.sh"; N=$(ct_runs); ct_law 'after the interruption'
[ "$(ct_runs)" -gt "$N" ] || fail 'the law commit after an interrupted run skipped the suite'
exit 0
