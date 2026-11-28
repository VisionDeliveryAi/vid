#!/bin/sh
# Purpose: selftest case — the issue form's {name} is blanked as the ticket's title is (FIX-BATCH-T3 §7, F-37's gap). On the form
# fixture's toy (GitHub manual, the toy issue form: its title `{step}: {name}`, a `{name}` line and a `{stage}` line in its body),
# S02's name in the plan and its stage's name in STAGES.md each hold a word of lib.sh's list. Convicts unless S02 is posted, its
# ticket passing the writer's check, and the issue's title and body show `(a word)` in the word's place and the word nowhere,
# the ticket file neither. Made-up data only. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "form-name-blanked: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
pt_rs 's/^\(step S02 | name: \)/\1damn /'; grep -q '^step S02 | name: damn ' .vid/RUN-STATE.md || fail "S02's name was not planted"
sh "$CHECKS/plan.sh" change other "S02's name as the toy plants it" --trigger initial --expect 'the names as written' > "$T/out" 2>&1 || fail "S02's name could not be recorded"
sed 's/^STAGE-1 | The daily digest |/STAGE-1 | The damn daily digest |/' STAGES.md > "$T/st" && cat "$T/st" > STAGES.md
g commit -qam 'the stage name planted'; git rev-parse HEAD > .vid/tw/applied; tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified again'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual: its ticket refused, or the form'; }; N=$FM_N
TI=$(cat "$FAKEGH/issues/$N/title"); B=$FAKEGH/issues/$N/body
case $TI in 'S02: (a word) '*) ;; *) fail "the issue's title is not '{step}: {name}' blanked: $TI" ;; esac
grep -q '^(a word) ' "$B" || fail "the body's {name} line is not blanked: $(sed -n 1,3p "$B" | paste -sd '|' -)"
grep -q '(a word) daily digest' "$B" || fail "the body's {stage} line is not blanked"
! grep -qi damn "$B" && ! printf '%s' "$TI" | grep -qi damn || fail 'a word of the list reaches the issue'
! grep -qi damn "$FM_F" || fail 'a word of the list reaches the ticket'
echo 'form-name-blanked: ok'
