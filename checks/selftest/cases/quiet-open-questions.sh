#!/bin/sh
# Purpose: selftest case — while the run is quiet, the watcher says what is true (0.26.11.1.3, R4), checks/observe.sh on the observer's toy
# run, its clocks months old, the interval 60 s. With `run: active` and three valid Q lines, the quiet notice never says the build isn't
# waiting on an answer from you, names the three ids each with its gates, and says nothing of other work; with none open it says, as
# before, that it isn't waiting on you. With no step for three intervals and nothing holding, the heartbeat adds `no step for <h> h <m> m,
# though the run reads active: its session may have stopped`; it does not with a step inside two intervals, with a live round wait
# (.vid/round/wait), or with a live lock holder. Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap 'rm -rf "$T"; [ -n "$P" ] && kill "$P" 2>/dev/null; true' EXIT
cd "$T"; CASE=quiet-open-questions
. "$CHECKS/selftest/fixtures/observer-lib.sh"
Q='gone quiet'; N='isn.t waiting on an answer from you'
Q1="- Q1 · asked $(ago 4000) · gates ROW-004, ROW-005 · Should a digest go out when nothing changed?"
Q2="- Q2 · asked $(ago 3900) · gates app/billing · Is a refund allowed after thirty days?"
Q3="- Q3 · asked $(ago 3800) · gates all remaining work · Which currency do invoices use?"
quiet() { grep "$Q" "$T/notify.log" | tail -n 1; }
# A. three questions open: named, with their gates; no "isn't waiting"; nothing of other work
reset; rs active "$Q1
$Q2
$Q3"
tick; [ "$(nnote "$Q")" -eq 1 ] || fail 'no quiet notice with three questions open'
L=$(quiet); ! printf '%s\n' "$L" | grep -q "$N" || fail "the quiet notice says it isn't waiting on you, with three questions open: $L"
printf '%s\n' "$L" | grep -qF '3 questions to you are open: Q1 (gates ROW-004, ROW-005), Q2 (gates app/billing), Q3 (gates all remaining work)' || fail "the quiet notice does not name the three questions with their gates: $L"
! printf '%s\n' "$L" | grep -qiE 'other (work|things)' || fail "the quiet notice draws a conclusion about other work: $L"
# B. none open: as before, it isn't waiting on you
reset; rs active; tick; [ "$(nnote "$Q")" -eq 1 ] || fail 'no quiet notice with none open'; quiet | grep -q "$N" || fail "with none open the notice does not say it isn't waiting on you: $(quiet)"
# C. no step for three intervals, nothing holding: the heartbeat says what the age means
NS='observe: no step for 0 h 3 m, though the run reads active: its session may have stopped'
reset; rs active; hb "$(ago 185)" 'a step'; tick; grep -qF "$NS" .vid/HEARTBEAT.md || fail "no 'no step for' line after three intervals: $(grep 'observe:' .vid/HEARTBEAT.md | tail -n 3)"
grep -q 'observe: run activity [0-9]*s ago' .vid/HEARTBEAT.md || fail 'the raw activity line went'
# D. not with a step inside two intervals, a live round wait or a live lock holder
reset; rs active; hb "$(ago 100)" 'a step'; tick; ! grep -q 'observe: no step for' .vid/HEARTBEAT.md || fail 'the line came with a step inside two intervals'
reset; rs active; hb "$(ago 185)" 'a step'; mkdir -p .vid/round; printf 'start=%s\nmax=600\n' "$(date +%s)" > .vid/round/wait; tick; rm -f .vid/round/wait
! grep -q 'observe: no step for' .vid/HEARTBEAT.md || fail 'the line came with a live round wait'
sleep 300 & P=$!
reset; rs active; hb "$(ago 185)" 'a step'; mkdir -p .vid/ledger.lock; printf '%s\nstarted\n%s\n' "$P" "$(( $(date +%s) - 60 ))" > .vid/ledger.lock/holder; tick; rm -rf .vid/ledger.lock
! grep -q 'observe: no step for' .vid/HEARTBEAT.md || fail 'the line came while a live lock holder holds'
exit 0
