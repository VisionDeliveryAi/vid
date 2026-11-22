#!/bin/sh
# Purpose: selftest case — ViD's own state repository (GM-1 S2 step 2, M15; its case mode-state-repo). With no state-repo: answered
# the switch asks it (exit 3, `ask state-repo`) and writes nothing; once the owner's answer is recorded, the switch makes it private
# and completes, the lock and the records in it alone; FB-2 A1: it is made through vid-connect's start (its `connect state-repo:`
# step on the switch's output, the switch making none itself first). A state-repo: naming the spec repository is refused at the setup, and a
# settings file that names it anyway is refused by the switch, nothing written. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-state-repo: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
grep -v '^state-repo:' .vid/tw/settings > "$T/s" && mv "$T/s" .vid/tw/settings; grep -v 'key=state-repo ' .vid/plan/setup > "$T/s" && mv "$T/s" .vid/plan/setup
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"; gh_wclear
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 3 ] && grep -qx 'ask state-repo' "$T/mo" || fail "with no state-repo answered the switch exited $MN_RC and did not ask it"
[ ! -s "$FAKEGH/writes" ] || fail 'the switch wrote before the state repository was answered'
if sh "$CHECKS/planner.sh" setup state-repo owner/code-spec --words 'the spec one' > "$T/out" 2>&1; then fail 'planner.sh setup took the spec repository as state-repo'; fi
if sh "$CHECKS/planner.sh" setup state-repo Owner/Code-Spec --words 'the same, other case' > "$T/out" 2>&1; then fail 'planner.sh setup took the spec repository, spelt in another case, as state-repo'; fi
sh "$CHECKS/planner.sh" setup state-repo owner/vid-state --words 'a private one of its own, yes, make it' > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the state-repo answer was refused'; }
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "with state-repo answered the switch exited $MN_RC"
grep -q '^connect state-repo: ' "$T/mo" || fail 'the state repository was not made through the connect (no connect state-repo: step)'
[ "$(gh repo view owner/vid-state --json isPrivate --jq .isPrivate)" = true ] || fail 'the state repository was not made private'
grep -v '^owner/vid-state ' "$FAKEGH/writes" > "$T/w" && { cat "$T/w" >&2; fail 'a write went to a repository but state-repo:'; }
mn_project "$T/q"; grep -v '^state-repo:' .vid/tw/settings > "$T/s"; echo 'state-repo: Owner/Code-Spec' >> "$T/s"; mv "$T/s" .vid/tw/settings
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"; gh_wclear
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 1 ] || fail "a state-repo: naming the spec repository: the switch exited $MN_RC, not 1"
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'the refused switch wrote to GitHub'; }
echo 'mode-state-repo: ok'
