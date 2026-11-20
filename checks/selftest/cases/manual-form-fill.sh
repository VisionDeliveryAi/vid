#!/bin/sh
# Purpose: selftest case — in GitHub manual a first post is the project's own issue form filled in (GM-2 T3; its case
# manual-form-fill). On the form fixture's toy (fixtures/form.sh: the ticket writer's toy switched to manual, S04 working
# against S05 through fakes, the toy issue form with every placeholder committed as issue-form:, issue-parent: the epic):
# S02 posted first, then S04, a step with rows of four kinds (rows, a rule, a difference, a hostility row; no seam row),
# building on S02 (a ticket) and S03 (none), faking S05. S04's issue: its title the form's first line filled; its body the
# form's lines after it, each placeholder line filled, the seam line left out, every other line as it stands, and nothing
# else; every part of the full ticket a comment, part 1 among them, each opening `Ticket #<n>, part <k> of <m>, writing <h>.`;
# the ticket label. The record: the log's published line ends `form=<the form's hash> words="<the owner's words>"`;
# .vid/tw/form/issue-<n> holds each placeholder line and its filling in the form's order, the seam line's empty;
# .vid/tw/body/issue-<n> the test ids the body names. The applied INVENTORY.md holds two prose lines
# with a | above its vid-inventory block (`RULE-004 | …`, `toy | …`), which set no test's kind and name no test; S05, the step S04
# fakes, is posted before S04 and S04 is not blocked by it; S04's builds-on: is written with a tab once its ticket is written,
# and its blocked-by and not-yet-ticketed lines are as before; a form titled `# {step}: {requirements}` titles S03's issue so.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-form-fill: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'issue-parent: %s\n' "$FM_P" >> .vid/tw/settings
# two prose lines holding a | above the inventory's block, in the applied commit: neither is a test
awk '/^```vid-inventory/ && !d { print "RULE-004 | Reference information, a prose line"; print "toy | a word of the toy team'"'"'s, a prose line"; print ""; d = 1 } { print }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'the inventory, two prose lines above its block'; git rev-parse HEAD > .vid/tw/applied; tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified again'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
fm_post S05 || { cp "$T/post" "$T/out"; fail 'S05, the step S04 fakes, was not posted in manual'; }; N5=$FM_N
# S04's ticket written, then its builds-on: written with a tab
fm_prep S04 || { cp "$T/post" "$T/out"; fail "S04's ticket could not be written"; }; F4=$FM_F
TB=$(printf '\t'); pt_rs "s/builds-on: S02 S03 /builds-on: S02${TB}S03 /"; grep -q "builds-on: S02${TB}S03" .vid/RUN-STATE.md || fail 'the tab did not take'
sh "$CHECKS/github.sh" tw-post --words 'Yes, publish S04' "$F4" > "$T/post" 2>&1 || { cp "$T/post" "$T/out"; fail 'S04 was not posted in manual'; }
N4=$(sed -n 's/^ViD github: [a-z]* ticket #\([0-9]*\).*/\1/p' "$T/post")
D=$FAKEGH/issues/$N4
# the title, the form's first line filled
[ "$(cat "$D/title")" = 'S04: limits, backups, failures and the data move' ] || fail "the title is not the form's first line filled: $(cat "$D/title")"
# the body: the form filled, line for line, and nothing else
REQ=$(awk '/^## / { s = substr($0, 4); next } s == "Requirements" && /^The answers/ { s = "" } s == "Requirements" && /^> [A-Z]+-[0-9]+ [|]/ { print $2 }' "$F4" | paste -sd , - | sed 's/,/, /g')
[ "$REQ" = 'REQ-005, REQ-006, REQ-010, REQ-011' ] || fail "the ticket quotes other requirements than the toy's: $REQ"
{ printf '\n## What this delivers\n\nThe toy team'"'"'s own words: one line of what the step gives the user.\n\nThe full ticket is in the comments below.\n\n'
  printf -- '- Step, name, stage, lane and parent:\nS04\nlimits, backups, failures and the data move\n1, The daily digest\ndevagent\n#%s\n\n' "$FM_P"
  printf '## Requirements\n\n%s\n\n## Tests\n\n' "$REQ"
  printf 'ROW-002, ROW-009, ROW-011, ROW-018, HOS-003, DIF-001, RULE-004\nROW-002, ROW-009, ROW-011, ROW-018\nRULE-004\nDIF-001\nHOS-003\n\n'
  printf '## Depends on\n\n#%s\nS03\n\n## Works against fakes of\n\nS05\n\n## Done when\n\nThe toy team'"'"'s own checklist line.\n' "$N2"; } > "$T/want"
cmp -s "$T/want" "$D/body" || { diff "$T/want" "$D/body" > "$T/out" || :; fail 'the body is not the form filled in (want < > the body)'; }
# every part a comment, part 1 among them
L=$(awk -v n="$N4" '$1 == "published" && $2 == n' .vid/tw/log); M=$(printf '%s\n' "$L" | tr ' ' '\n' | sed -n 's/^parts=//p')
[ -n "$M" ] && [ "$M" -ge 1 ] || fail "the published line names no parts: $L"
[ "$(ls "$D/comments" | grep -c .)" = "$M" ] || fail "the issue holds $(ls "$D/comments" | grep -c .) comments for $M parts"
k=1; while [ "$k" -le "$M" ]; do head -n 1 "$D/comments/$k" | grep -qE "^Ticket #$N4, part $k of $M, writing [0-9a-f]+\.\$" || fail "comment $k is not part $k of $M: $(head -n 1 "$D/comments/$k")"; k=$((k + 1)); done
grep -qx 'ticket' "$D/labels" || fail 'the issue holds no ticket label'
# the record
FH=$(git rev-parse HEAD:forms/issue.md)
printf '%s\n' "$L" | grep -qE " parts=$M at=[^ ]+ form=$FH words=\"Yes, publish S04\"\$" || fail "the published line does not end with the form's hash and the owner's words — $L"
printf '{step}\tS04\n{name}\tlimits, backups, failures and the data move\n{stage}\t1, The daily digest\n{lane}\tdevagent\n{parent}\t#%s\n{requirements}\t%s\n' "$FM_P" "$REQ" > "$T/fr"
printf '{tests}\tROW-002, ROW-009, ROW-011, ROW-018, HOS-003, DIF-001, RULE-004\n{tests:row}\tROW-002, ROW-009, ROW-011, ROW-018\n{tests:rule}\tRULE-004\n{tests:difference}\tDIF-001\n{tests:hostility}\tHOS-003\n{tests:seam}\t\n' >> "$T/fr"
printf '{blocked-by}\t#%s\n{not-yet-ticketed}\tS03\n{fakes}\tS05\n' "$N2" >> "$T/fr"
{ printf '{full-ticket}\tThe full ticket is in the comments below.\n'; cat "$T/fr"; } > "$T/fr2"
cmp -s "$T/fr2" ".vid/tw/form/issue-$N4" || { diff "$T/fr2" ".vid/tw/form/issue-$N4" > "$T/out" 2>&1 || :; fail "the form record is not each placeholder line and its filling, in the form's order"; }
printf '%s\n' DIF-001 HOS-003 ROW-002 ROW-009 ROW-011 ROW-018 RULE-004 > "$T/ids"
cmp -s "$T/ids" ".vid/tw/body/issue-$N4" || { cp ".vid/tw/body/issue-$N4" "$T/out" 2>/dev/null || :; fail 'the kept body ids are not the test ids the body names'; }
# S05, faked, is no blocker of S04
[ "$(cat "$D/blocked-by" 2>/dev/null | paste -sd , -)" = "$N2" ] || fail "S04's issue is blocked by '$(cat "$D/blocked-by" 2>/dev/null | paste -sd , -)', not by #$N2 alone (S05 is a fake, posted before it)"
# a title with any one-line placeholder
sed '1s/.*/# {step}: {requirements}/' forms/issue.md > "$T/f" && cat "$T/f" > forms/issue.md; g commit -qam 'the form, titled with its requirements'
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted with a title of {step} and {requirements}'; }
R3=$(awk '/^## / { s = substr($0, 4); next } s == "Requirements" && /^The answers/ { s = "" } s == "Requirements" && /^> [A-Z]+-[0-9]+ [|]/ { print $2 }' "$FM_F" | paste -sd , - | sed 's/,/, /g')
[ "$(cat "$FAKEGH/issues/$FM_N/title")" = "S03: $R3" ] || fail "S03's title is not '{step}: {requirements}' filled: $(cat "$FAKEGH/issues/$FM_N/title")"
exit 0
