#!/bin/sh
# Purpose: selftest case — the test-running rules moved out of vid-develop
# (v0.9.7.0.2 spec 3.5, R10; §6 D-3). Each moved paragraph's first
# sentence, from a fixed list, is in skills/vid-test-manager/SKILL.md and no
# longer in skills/vid-develop/SKILL.md; develop's one-line calls are
# present (in vid-develop, or in vid-build, where v0.9.7.0.7 3.1 moved the
# per-slice steps word for word); the moved pass is under the manager and
# not under develop.
# Plugin repository only (a project has no skills/ of ViD's). Env: CHECKS.
set -eu
SK="$CHECKS/../skills"
[ -f "$SK/vid-develop/SKILL.md" ] || exit 0
D="$SK/vid-develop/SKILL.md"; M="$SK/vid-test-manager/SKILL.md"
fail() { echo "moved-text: $*" >&2; exit 1; }
[ -f "$M" ] || fail 'no vid-test-manager skill'
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
flat "$D" > "${TMPDIR:-/tmp}/moved-d.$$"; flat "$M" > "${TMPDIR:-/tmp}/moved-m.$$"
{ cat "${TMPDIR:-/tmp}/moved-d.$$"; [ ! -f "$SK/vid-build/SKILL.md" ] || flat "$SK/vid-build/SKILL.md"; } > "${TMPDIR:-/tmp}/moved-k.$$"
trap 'rm -f "${TMPDIR:-/tmp}/moved-d.$$" "${TMPDIR:-/tmp}/moved-m.$$" "${TMPDIR:-/tmp}/moved-k.$$"' EXIT
moved() { grep -qF -- "$1" "${TMPDIR:-/tmp}/moved-m.$$" || fail "not in vid-test-manager: $1"; grep -qF -- "$1" "${TMPDIR:-/tmp}/moved-d.$$" && fail "still in vid-develop: $1"; return 0; }
kept() { grep -qF -- "$1" "${TMPDIR:-/tmp}/moved-k.$$" || fail "vid-develop and vid-build lack the call: $1"; }
moved 'It measures one test environment, picks two or three, proves two side by side and records them in `.vid/budget`; until it has, every run gets one environment.'
moved 'Never run the whole ledger early to find them — it runs rows of steps not yet built, which fail whether or not they are broken.'
moved 'With two or more proved test environments, `sh checks/metrics.sh checkpoint` — and the progress update — shows `checkpoint due n=<n> built=<b> plan=<p>` once the rows of closed steps reach a third of the plan'"'"'s rows, and a second time at two thirds.'
moved 'freezes what it tests — a full run HEAD'"'"'s tree, a scoped run the working tree as it is at the start — runs it in its own folder and compose project'
moved 'Inside a builder or fix pass the ledger runs SCOPED'
moved 'At every slice close append `sh checks/testenv.sh leftovers` to the slice report (after the closure)'
moved 'prints the required rows: the steps'"'"' own rows, the rows of the steps they build on'
kept 'Nobody runs the test runner directly. To get a test result, make a request to the test manager.'
kept 'The test manager measures the environments before the first run (`vid-test-manager`, test environments).'
kept 'After any red, read the sorted groups the request'"'"'s result gives; hand setup groups to test-authors in bulk'
kept 'When a checkpoint is due, request one (`--type checkpoint`); it never blocks admission, close or claim'
kept 'observed red by a `prove-red` request'
kept 'Each of its runs is a `prove-red` request.'
kept 'Request an `iterate` run for the rows under work (their built neighbours and, after a harness change, the alarm set)'
kept 'Every run is a request to the test manager (`vid-test-manager`).'
kept 'a breach observed in one engine only is logged'
kept 'At every slice close and before completion, the test manager'"'"'s leftovers list must be empty (`vid-test-manager`).'
kept 'Request the close as one batch: `--type close --steps <ids> --batch --phase1 <file> --phase2 <file>`, its groups built from close-rows'"'"' list'
kept 'is a `full` request, claimed the same way with `--steps`'
kept 'the final `full` request (Slice close, "The last slice close")'
kept '(6) the test requests: type, rows, and the selection'
[ -f "$SK/vid-test-manager/passes/test-environments.md" ] || fail 'the test-environments pass is not under vid-test-manager'
[ ! -f "$SK/vid-develop/passes/test-environments.md" ] || fail 'the test-environments pass is still under vid-develop'
grep -q 'passes/test-environments.md' "$D" && fail 'vid-develop still names the pass file'
exit 0
