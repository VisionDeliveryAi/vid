#!/bin/sh
# Purpose: selftest case — a project whose checks/ predates 0.9.5 (v0.9.5
# spec 3.2, 3.4; §7 case 25). Where the plugin's hooks/stop-failure.sh sits
# beside checks/: with a run for the session but no checks/records-version,
# the death record appends nothing and exits 0. Where ViD's skills sit
# beside checks/: develop's start reads checks/records-version and names
# the refresh step. v0.9.6.2 (3.9, R8; §6 case 22): a `records: 3`
# project is told to refresh too, and until then develop passes plan.sh
# change its two arguments alone — the decision arguments only under
# `records: 4` or later (v0.9.6.2.1: every version gate reads "or later");
# develop writes records=4. v0.9.7.0.1 (3.2): develop writes records=5,
# and a `records: 4` project is told to refresh; until then a test-author
# brief's run command carries no --role and every agent in its own
# worktree still records its home with plan.sh home --brief. v0.9.7.0.2
# (3.7, R12; rewritten): one rule replaces the per-version ones — a
# checks/ whose records-version is absent or below 6 is told to refresh
# and develop stops before building, recorded as a stop; develop writes
# records=6, and no rule for an older checks/ remains. v0.9.7.0.3 (3.4,
# R7): the same rule at 7 — develop writes records=7 and stops below 7;
# vid-fix writes records=7, since it writes analyst-done. v0.9.7.0.4
# (3.4, R7): the same rule at 8 — develop writes records=8 and stops below
# 8; vid-fix writes no new field and stays at records=7. v0.9.7.0.5 (R7):
# vid-fix writes records=8 — its graders get the scope sentence and it
# follows vid-verify's recording and hold release. v0.9.7.0.6 (3.7, R10):
# checks/ is 9 and develop stops below 9 (it needs the observer that reads
# agent-start's transcript=); no verb's stamp changes — develop and fix
# both stay at records=8, since the field is the hook's. v0.9.7.0.7 (3.8,
# R12): checks/ is 10; develop and fix write records=10 and both stop below
# 10 (their builders and fixers hand back through brief.sh return).
# v0.9.7.0.8: checks/ is 11 (a queued request's holders, the slot-reclaimed
# event — both checks/test.sh's own); develop and fix stay at records=10
# and still stop below 10. v0.9.7.0.9 (3.9, R15): checks/ is 12; develop
# writes records=12 and stops below 12 (it calls observe.sh start and
# test.sh analyst-due, which only a 12 checks/ has); vid-fix calls neither
# and stays at records=10, stopping below 10. v0.9.7.0.10 (3.5, R11):
# checks/ is 13 and RECORDS.md says so (the teardown events, overhead=,
# the proof's harness hash, the harness-upgrade events); revision 4:
# develop writes records=13 and stops below 13 — it calls harness.sh
# rules, which an older harness.sh ignores — and runs that check right
# after the version check; vid-fix calls nothing new and stays at
# records=10. v0.9.7.0.11 (3.15, R15): checks/ is 14 and RECORDS.md says
# so; develop writes records=14 and stops below 14 — its upgrade step reads
# harness.sh rules' targets and rules: 2; vid-fix stays at records=10.
# v0.9.7.0.12 (3.11, R11): checks/ is 15 and RECORDS.md says so; develop
# writes records=15 and stops below 15 — its close writes groups and claims
# by batch; vid-fix stays at records=10.
# v0.9.7.1 (3.13, R13): checks/ is 16 and RECORDS.md says so; develop and
# vid-fix both write records=16 and stop below 16 — they brief with the
# selection and hand back through `return --agent`.
# v0.9.7.2 (3.12, R16): checks/ is 17 and RECORDS.md says so; develop and
# vid-fix both write records=17 and stop below 17 — develop sets the
# strategy, writes catch-up briefs and defers through 17's commands, and
# fix resolves deferrals.
# v0.9.7.3 (3.10, R10): checks/ is 18 and RECORDS.md says so; develop and
# vid-fix both write records=19 and stop below 18 — briefs quote decisions
# by label, the hook records refusals and the certificate.
# v0.9.7.4 (3.11, R12): checks/ is 19 and RECORDS.md says so; develop and
# vid-fix both write records=19 and stop below 19 — develop writes the
# delegated mark through metrics.sh delegated.
# v0.9.8 (R14): checks/ is 20 and RECORDS.md says so; develop and vid-fix both write records=20 and stop below 20.
# v0.26.10.2 (R18): checks/ is 22 and RECORDS.md says so; develop and vid-fix both write records=22 and stop below 22;
# their refresh first lists the project's local changes (R5). v0.26.10.3 (R14): checks/ is 23 and RECORDS.md says so; develop and
# vid-fix both write records=23 and stop below 23. v0.26.10.4 (R14): checks/ is 24 and RECORDS.md says so; develop and
# vid-fix both write records=24 and stop below 24. v0.26.10.5 (R17): checks/ is 25 and RECORDS.md says so; develop and
# vid-fix both write records=25 and still stop below 24 (a project without STAGES.md is unchanged); a project holding
# STAGES.md stops below 25.
# In a project neither file exists and the case proves
# nothing. Env: CHECKS.
set -eu
H="$CHECKS/../hooks/stop-failure.sh"
D="$CHECKS/../skills/vid-develop/SKILL.md"
FX="$CHECKS/../skills/vid-fix/SKILL.md"
fail() { echo "version-skew: $*" >&2; exit 1; }
if [ -f "$H" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  mkdir -p "$T/p/.vid" "$T/p/checks"; cd "$T/p"; git init -q
  printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
  printf '{"session_id":"S1","cwd":"%s","hook_event_name":"StopFailure","error":"rate_limit"}' "$T/p" | sh "$H" || fail 'the hook exited non-zero'
  [ ! -s .vid/metrics-events ] || fail 'a pre-0.9.5 checks/ got a died line'
fi
if [ -f "$D" ]; then
  F=$(tr '\n' ' ' < "$D" | tr -s ' ')
  has() { printf '%s' "$F" | grep -qF -- "$1"; }
  # v0.9.7.0.2 (3.7, R12): one rule — a checks/ older than this plugin stops develop before building
  has 'Read `checks/records-version` first. If it is absent or below 24, the project'"'"'s checks/ predates this plugin: tell the owner it needs the refresh and stop before building; so too a project holding STAGES.md whose checks/ is below 25' || fail "develop's start does not stop on a checks/ older than records: 24"
  has 'first run `sh "${CLAUDE_PLUGIN_ROOT}/checks/local-changes.sh"` from the project'"'"'s top level and show the owner its list' || fail "develop's refresh does not list the local changes first"
  has 'commit it alone with `VID_ROLE=fix`, its subject `Refresh checks/ to VID <version>`' || fail "develop's refresh commit does not keep its subject"
  has 'Record the stop as `run: stopped checks/ needs the refresh`' || fail 'develop does not record the refresh stop'
  grep -q 'name=develop state=start session=$CLAUDE_CODE_SESSION_ID records=25"`' "$D" || fail 'develop does not write records=25'
  has '**The harness upgrade (v0.9.7.0.10 3.6, R13; v0.9.7.0.11 3.2, R2).** Right after the version check, run `sh checks/harness.sh rules`.' || fail "develop does not run harness.sh rules right after the version check"
  grep -q 'name=fix state=start session=$CLAUDE_CODE_SESSION_ID records=25"`' "$FX" || fail 'vid-fix does not write records=25'
  tr '\n' ' ' < "$FX" | tr -s ' ' | grep -qF 'Read `checks/records-version` first. If it is absent or below 24, the project'"'"'s checks/ predates this plugin' || fail 'vid-fix does not stop on a checks/ older than records: 24'
  tr '\n' ' ' < "$FX" | tr -s ' ' | grep -qF 'so too a project holding STAGES.md whose checks/ is below 25' || fail 'vid-fix does not stop a staged project on a checks/ older than records: 25'
  # the per-version degradations are gone: no rule for an older checks/ remains
  printf '%s' "$F" | grep -qE 'If it says `records: [0-9]+`|`records: [0-9]+` or later' && fail 'develop still carries a rule for an older checks/'
  printf '%s' "$F" | grep -qF 'until the refresh' && fail 'develop still builds on an older checks/ until the refresh'
  [ "$(sed -n 's/^records: //p' "$CHECKS/records-version")" = 25 ] || fail 'checks/records-version is not 25'
  [ "$(sed -n 's/^records: //p' "$CHECKS/../RECORDS.md")" = 25 ] || fail 'RECORDS.md does not say records: 25'
fi
exit 0
