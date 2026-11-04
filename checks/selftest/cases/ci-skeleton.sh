#!/bin/sh
# Purpose: selftest case — the skeleton's CI under ticket-mode CI scope (v0.26.10.12 spec R1, R9). `ticket.sh
# skeleton-body` asks for a CI workflow that on a pull request (opened, synchronize, reopened, edited) runs the
# selection of the return block's ci-scope: line — every test when it is missing or unreadable, the description read
# through an environment variable — on a manual start of main runs every test on the run's own commit, and runs nothing
# on a push to main; its return block template carries `skeleton: run-full:`. return-check: the new skeleton ticket's
# block without the run-full line is refused, naming it, and passes with it; an older skeleton ticket (its body asking
# for no run-full line) passes without it, as does a skeleton block checked without --ticket. vid-replan §2 checks the
# new triggers and writes run-full: into the vid-code block (in the plugin repository). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ci-skeleton: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
sh checks/ticket.sh skeleton-body --req REQ-001 > "$T/out" 2>&1 || fail 'skeleton-body failed'
SB=.vid/tickets/skeleton.md; F=$(tr '\n' ' ' < "$SB" | tr -s ' ')
has() { printf '%s' "$F" | grep -qF -- "$1" || fail "the skeleton ticket does not say: $1"; }
has 'on a pull request (opened, synchronize, reopened, edited), reads the `ci-scope:` line of the pull request'"'"'s vid-return block and runs only the tests it selects; when the line is missing or unreadable it runs every test.'
has 'The description is read through an environment variable, never pasted into a shell step;'
has 'on a manual start of main, runs every test on the commit it is started on (the run'"'"'s own commit; no commit input);'
has 'runs nothing on a push to main'
has 'run-full (how the full run is started)'
printf '%s' "$F" | grep -qF 'on every push to main' && fail 'the skeleton ticket still asks for a run on every push to main'
grep -qx 'skeleton: run-full: <how the full run is started>' "$SB" || fail "the return block template has no skeleton: run-full: line"
sh checks/ticket.sh body "$SB" > /dev/null 2>&1 || fail 'the skeleton ticket does not hold its stamp'
# return-check
blk() { printf 'The skeleton.\n\n```vid-return\nticket: #4\nrows: none\nskeleton: test-framework: the runner\nskeleton: test-dir: tests/acceptance\nskeleton: run-one: make test ONLY=<names>\nskeleton: ci-workflow: CI\nskeleton: report: vid-junit-<run attempt>\n%bdecisions:\n  - none\ndiscovered:\n  - none\nlaw-needed:\n  - none\nquestions:\n  - none\n```\n' "$1"; }
rc() { sh checks/ticket.sh return-check "$@" > "$T/out" 2>&1; }
blk '' > "$T/old.md"; blk 'skeleton: run-full: gh workflow run CI --ref main\n' > "$T/new.md"
if rc "$T/old.md" --ticket "$SB"; then fail 'a new skeleton block without run-full passed'; fi
grep -q 'has no skeleton: run-full: line' "$T/out" || fail 'the refusal does not name the run-full line'
rc "$T/new.md" --ticket "$SB" || fail 'a new skeleton block with run-full was refused'
grep -v '^skeleton: run-full:' "$SB" > "$T/older.md"
rc "$T/old.md" --ticket "$T/older.md" || fail "an older skeleton ticket's block without run-full was refused"
rc "$T/old.md" || fail 'a skeleton block without run-full was refused without --ticket'
# the skill — only in the plugin repository (a project has checks/ alone); vid-plan no longer describes the CI (0.26.10.12.2)
[ -d "$CHECKS/../skills/vid-replan" ] || exit 0
R=$(tr '\n' ' ' < "$CHECKS/../skills/vid-replan/SKILL.md" | tr -s ' ')
printf '%s' "$R" | grep -qF 'runs on a pull request (opened, synchronize, reopened, edited) only the tests the `ci-scope:` line of its return block selects' || fail 'vid-replan §2 does not check the pull-request trigger'
printf '%s' "$R" | grep -qF 'runs every test on a manual start of main (on the run'"'"'s own commit, no commit input) and nothing on a push to main' || fail 'vid-replan §2 does not check the manual start and the push'
printf '%s' "$R" | grep -qF '`report:` — and `run-full:` beside them, committed alone' || fail 'vid-replan §2 does not write run-full: into the vid-code block'
printf '%s' "$R" | grep -qF 'runs on pull requests and pushes to main' && fail 'vid-replan §2 still checks pull requests and pushes to main'
exit 0
