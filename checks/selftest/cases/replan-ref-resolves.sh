#!/bin/sh
# Purpose: selftest case — the re-plan's check judges the apply's own plan-change arguments as the apply's plan change does
# (FIX-BATCH-T3 §6, F-35). On the form fixture's toy (GitHub manual), S02 posted as #N, ROW-021 landed, and the owner's list's
# question Q3 asked (a `queue-asked Q3` event). Convicts unless: (b) a candidate citing question:Q9, which the list never gave,
# and (c) one citing ticket:999, no published ticket, break rule 6 naming the reference; (d) `plan.sh args` resolves
# question:Q5 by develop's `question n=5` event, and not without it; (e) a candidate adding S06 and citing step:S06 is clean
# though RUN-STATE's block and the last accepted plan hold no S06; (f) every line counts: a bad reference on an unchanged
# subject's line, or on the first of a subject's two lines, and a bad trigger on an earlier line or an unchanged subject's line,
# each break rule 6; (g) for triggers and evidence with blanks, a line with no tab, a blank line with a carriage return and a
# block whose new step follows a ## line, the check breaks rule 6 exactly when
# `plan.sh change`, given the apply's arguments for the same changes, is refused; (h) a ticket-mode admission's refusal, cited
# as refusal:<attempt> (a step the plan lacks, refused in either mode), is clean; (a) a candidate citing question:Q3 is clean, and its apply on the owner's yes records the
# plan change with question:Q3 as its evidence. Made-up data only. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-ref-resolves: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
awk '{ print } /^ROW-020 / && !d { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-021 landed'; HC=$(git rev-parse --short HEAD)
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
sh "$CHECKS/event.sh" 'queue-asked Q3 what=question' > /dev/null || fail 'the queue-asked event could not be recorded'
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
C=$T/cand; mkdir -p "$C"; printf 'none\n' > "$C/review"
blk | sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e '/^needs ROW-017 /{p;s/.*/needs ROW-021 | -/;}' > "$C/block"
S06='step S06 | name: the failure log | modules: digest | builds-on: S02 | rows: ROW-018 | lane: devagent'
E=$T/six; mkdir -p "$E"; sed -e 's/^\(step S04 .*\) ROW-018 /\1 /' -e "/^step S05 /{p;s/.*/$S06/;}" "$C/block" > "$E/block"
# ch <dir> <line>…: the candidate's changes, one argument a line (fields split by tabs); chk <dir>: the check, its exit in RC
ch() { _d=$1; shift; : > "$_d/changes"; for _l; do printf '%s\n' "$_l" >> "$_d/changes"; done; }
chk() { RC=0; sh "$CHECKS/replan.sh" check "$1/block" > "$T/out" 2>&1 || RC=$?; }
broke() { chk "$1"; [ "$RC" = 1 ] && grep -q "^rule-6 .*$2" "$T/out" || fail "$3 (exit $RC)"; }
clean() { chk "$1"; [ "$RC" = 0 ] && ! grep -q '^rule-' "$T/out" || fail "$2 (exit $RC)"; }

# (b), (c): references the apply would refuse break the check, naming them
ch "$C" "S02${TB}owner-answer${TB}question:Q9${TB}ROW-021 joins #$N"; broke "$C" 'question:Q9' '(b) question:Q9, never asked, did not break rule 6'
ch "$C" "S02${TB}scope-change${TB}ticket:999${TB}ROW-021 joins #$N"; broke "$C" 'ticket:999' '(c) ticket:999, no published ticket, did not break rule 6'
# (d) develop's question event still resolves, read only
pa() { RC=0; sh "$CHECKS/plan.sh" args --block "$C/block" --trigger owner-answer --evidence "$1" --expect 'nothing moves' > "$T/out" 2>&1 || RC=$?; }
pa question:Q5; [ "$RC" = 1 ] || fail "(d) plan.sh args passed question:Q5 with no event for it (exit $RC)"
sh "$CHECKS/event.sh" 'question n=5 state=asked gates=all' > /dev/null
find .vid -type f -exec cksum {} + | sort > "$T/w0"
pa question:Q5; [ "$RC" = 0 ] || fail "(d) plan.sh args refused question:Q5 with its question n=5 event (exit $RC)"
pa question:Q3; [ "$RC" = 0 ] || fail "(d) plan.sh args refused question:Q3, the list's own (exit $RC)"
find .vid -type f -exec cksum {} + | sort | cmp -s - "$T/w0" || fail '(d) plan.sh args wrote under .vid'
# (e) a new step of the candidate resolves against the candidate's block
blk | grep -q '^step S06 ' && fail '(e) the ratified block already holds S06'
ch "$E" "S02${TB}scope-change${TB}commit:$HC${TB}ROW-021 joins #$N" "S04${TB}scope-change${TB}commit:$HC${TB}ROW-018 leaves S04" "S06${TB}scope-change${TB}step:S06${TB}S06 holds ROW-018"
clean "$E" '(e) step:S06, the candidate'"'"'s own new step, broke the check'
# (f) every line counts
ch "$C" "S02${TB}scope-change${TB}commit:$HC${TB}ROW-021 joins #$N" "S03${TB}scope-change${TB}ticket:999${TB}nothing moves"
broke "$C" 'ticket:999' "(f) a bad reference on an unchanged subject's line passed"
ch "$C" "S02${TB}owner-answer${TB}ticket:999${TB}ROW-021 joins #$N" "S02${TB}owner-answer${TB}question:Q3${TB}ROW-021 joins #$N"
broke "$C" 'ticket:999' "(f) a bad reference on a subject's first line passed"
ch "$C" "S02${TB}bogus${TB}-${TB}ROW-021 joins #$N" "S02${TB}scope-change${TB}commit:$HC${TB}ROW-021 joins #$N"
broke "$C" 'bogus' "(f) a bad trigger on a subject's earlier line passed"
ch "$C" "S02${TB}scope-change${TB}commit:$HC${TB}ROW-021 joins #$N" "S03${TB}owner-answer,typo${TB}question:Q3${TB}nothing moves"
broke "$C" 'typo' "(f) a bad trigger on an unchanged subject's line passed"
# (g) agreement: the check breaks rule 6 exactly when plan.sh change, given the apply's arguments, refuses them
# in a copy of the toy, the applied commit set to the target and the candidate's block in RUN-STATE, as the apply's steps put
# them before its plan change (checks/replan.sh steps15, checks/land.sh plan_change); the clean line, last, is the control
# args <changes>: the apply's arguments as its proposal's changes give them (checks/replan.sh's apply, as written before F-35)
args() { TG=$( { cut -f2 "$1" 2>/dev/null || :; } | tr ',' '\n' | grep . | awk '!s[$0]++' | paste -sd , -); EV=$( { cut -f3 "$1" 2>/dev/null || :; } | tr ',' '\n' | grep -v '^-*$' | awk '!s[$0]++' | paste -sd , -)
  EX=$( { cut -f4 "$1" 2>/dev/null || :; } | grep . | paste -sd ';' - | sed 's/;/; /g'); [ -n "$TG" ] || { TG=scope-change; EV=commit:$HC; }; [ -n "$EX" ] || EX='the plan as the re-plan proposal holds it'; }
cp -R "$T/toy" "$T/x0"
# agree <dir> <label>: the changes as the proposal keeps them (carriage returns out), the block as the candidate's
agree() { _a=$1; shift; tr -d '\r' < "$_a/changes" > "$T/cc"; args "$T/cc"; rm -rf "$T/x"; cp -R "$T/x0" "$T/x"
  ( cd "$T/x" && git rev-parse HEAD > .vid/tw/applied && awk -v B="$_a/block" '/^## The plan/ { s = 1 } s && /^```vid-plan[ \t]*$/ { print; while ((getline l < B) > 0) print l; b = 1; next } b && /^```[ \t]*$/ { b = 0; s = 0 } !b { print }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
    if [ -n "$EV" ]; then sh "$CHECKS/plan.sh" change rows 'the agreement scene' --trigger "$TG" --evidence "$EV" --expect "$EX"; else sh "$CHECKS/plan.sh" change rows 'the agreement scene' --trigger "$TG" --expect "$EX"; fi ) > "$T/pc" 2>&1 && PC=0 || PC=1
  chk "$_a"; if grep -q '^rule-6 ' "$T/out"; then CK=1; else CK=0; fi
  [ "$PC" = "$CK" ] || { cat "$T/pc" >> "$T/out"; fail "(g) $1: plan.sh change exited $PC and the check broke rule 6 $CK"; }; }
ch "$C" "S02${TB}owner-answer, scope-change${TB}question:Q3${TB}ROW-021 joins #$N"; agree "$C" 'triggers with a blank'
ch "$C" "S02${TB}owner-answer${TB}question:Q3, commit:$HC${TB}ROW-021 joins #$N"; agree "$C" 'evidence with a blank after a comma'
ch "$C" "S02${TB}owner-answer${TB}question: Q3${TB}ROW-021 joins #$N"; agree "$C" 'evidence with a blank inside it'
ch "$C" "S02${TB}scope-change${TB}commit:$HC${TB}ROW-021 joins #$N" 'note'; agree "$C" 'a line with no tab'
ch "$C" "S02${TB}owner-answer${TB}question:Q3${TB}ROW-021 joins #$N" "$(printf '\r')"; agree "$C" 'a blank line with a carriage return'
G=$T/hd; mkdir -p "$G"; sed '/^step S06 /i\
## Additional work
' "$E/block" > "$G/block"; cp "$E/changes" "$G/changes"; grep -q '^## Additional work' "$G/block" || fail '(g) the block with a ## line was not made'
agree "$G" 'a block whose S06 follows a ## line'
ch "$C" "S02${TB}owner-answer${TB}question:Q3${TB}ROW-021 joins #$N"; agree "$C" 'a clean line'
# (h) a ticket-mode admission's refusal resolves: S99, no step of the plan, refused (plan.sh start, in either mode)
RC=0; sh "$CHECKS/plan.sh" start S99 > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail '(h) S99, no step of the plan, was admitted, so no refusal was recorded'
AT=$(grep '^refused phase=admission ' .vid/metrics-events | tail -n 1 | sed -n 's/.* attempt=\([^ ]*\).*/\1/p'); [ -n "$AT" ] || fail '(h) no admission refusal was recorded'
ch "$C" "S02${TB}gate-refusal${TB}refusal:$AT${TB}ROW-021 joins #$N"; clean "$C" "(h) refusal:$AT, a ticket-mode refusal, broke the check"
# (a) the list's question: clean, and applied on the owner's yes with it as its evidence
ch "$C" "S02${TB}owner-answer${TB}question:Q3${TB}ROW-021 joins #$N"; clean "$C" '(a) question:Q3, the list'"'"'s own, broke the check'
pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail '(a) the analysis citing question:Q3 was refused'
# the stored proposal's changes, given a line holding a carriage return after the analysis: the apply's first gate judges the
# bytes the apply reads, and refuses there, not in its dry run
cp .vid/next/proposal/changes "$T/pc0"; printf '\r\n' >> .vid/next/proposal/changes
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 're-plan rule' "$T/out" && ! grep -q 'dry run' "$T/out" || fail "(a) the proposal given a carriage-return line was not refused at the apply's first gate (exit $RC)"
cat "$T/pc0" > .vid/next/proposal/changes
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "(a) the apply citing question:Q3 exited $RC"
grep -l 'question:Q3' .vid/plans/decisions/*.why 2>/dev/null | xargs grep -l 'result=accepted' > /dev/null 2>&1 || { ls .vid/plans/decisions >> "$T/out"; fail '(a) no accepted plan change records question:Q3 as its evidence'; }
echo 'replan-ref-resolves: ok'
