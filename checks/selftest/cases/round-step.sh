#!/bin/sh
# Purpose: selftest case — ViD's round (v0.26.10.25.1 R4, R5, R8, R10), checks/round.sh on the toy and the fake gh. next publishes, a refusal once; a stray ticket stops; an ask is decided, saved before it is posted; a
# merge recorded once, its issue closed, the interim closed written; a merge with no decision, one line; a question beside a ticket that goes on; a held row waits, nothing answered; the switch, labelled, and a held product
# failure answered by nothing; the alarms, once; a lost lock; a pause; wait; nothing-left, held back by a grade ask out and not by a lost one; the read's calls; vid-run's stops and never-list. Env: CHECKS.
# selftest-limit: 1440 s — 318 to 476 s alone under load, past 900 s in the suite (FB-2 C1, the runner's rule, ×3)
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "round-step: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; DS=$CHECKS/decide.sh; R=owner/code; SR=$T/gh/repos/owner%code-spec/remote.git; mkdir -p "$T/r"
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
tw_hand 'candidate 1'   # v0.26.10.26.1: a later stage's candidate, so S01's close stays a step close, C1, as this case proves (stage 0 names none)
# next: the skeleton published and saved; a step refused, once
rd next; [ "$RC" = 0 ] || fail 'next failed'; ok '^published 1$'; ok '^refused start S02'; git -C "$SR" rev-parse -q --verify refs/heads/vid-state/records > /dev/null || fail 'no save after the post'; rd next; no '^refused start S02'; no '^published'
# a stray ticket stops the step and names it
n=$(gh issue create -R $R --title x --body y --label ticket | sed 's/.*\///'); rd step; [ "$RC" = 4 ] && grep -q "stop stray: #$n" "$T/out" || fail 'a stray ticket did not stop the step'; rd next; [ "$RC" = 4 ] && ! grep -q '^published' "$T/out" || fail 'next published past a stray ticket'; gh issue close "$n" -R $R
# an ask: decided, the save before the post
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null; br() { git -C "$W" checkout -q -B "$1" origin/main 2>/dev/null; git -C "$W" -c user.name=a -c user.email=a@b commit -q --allow-empty -m "$1"; git -C "$W" push -q -f origin "$1"; git -C "$W" rev-parse HEAD; }
pr() { gh pr create -R $R --head "$1" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$2")" | sed 's/.*\///'; }; ask() { printf 'vid: decide %s\nby: MR\n' "$2" > "$T/c"; gh pr comment "$1" -R $R --body-file "$T/c" > /dev/null; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rep() { Q=$1; H=$2; shift 2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 2' "$H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases "$@")"; send "$Q"; }
H=$(br ticket-1); P=$(pr ticket-1 1); h=$(printf %s "$H" | cut -c1-12); rr_put "pr-$P-$h-1" faults/ROW-003/cases-alpha.xml "$(rr_cases ROW-003=fail:gone)"; rep "pr-$P-$h-1" "$H" ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass; rr_put "grade-pr-$P-$h-1" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-003 kept — a\nROW-004-T1 kept — b' "$H")"; send "grade-pr-$P-$h-1"
mv "$T/bin/gh" "$T/bin/gh-fake"; cat > "$T/bin/gh" <<G
#!/bin/sh
[ ! -f "$T/nopost" ] || case "\$1 \$2" in 'issue create') echo 'a 502' >&2; exit 1 ;; esac
case "\$1 \$2 \${5:-}" in 'pr comment '*) f=\$(printf %s "\$*" | sed 's/.*--body-file //'); if head -n 1 "\$f" | grep -q '^vid: decision '; then git -C "$SR" show "vid-state/records:decide/pr-$P-$h.rows" > /dev/null 2>&1 && echo saved >> "$T/order" || echo unsaved >> "$T/order"; fi ;; esac
exec "$T/bin/gh-fake" "\$@"
G
chmod +x "$T/bin/gh"; ask "$P" "$H"; rd step; [ "$RC" = 0 ] || fail "step failed: $(cat "$T/out")"; ok "^decided $P $h ticket: accepted"; [ "$(cat "$T/order")" = saved ] || fail 'the decision was posted before the save'; [ ! -f .vid/round-errors ] || fail 'a clean step left the error count'; rd step; ok '^idle'; no '^decided'
# the merge: recorded once, the issue closed; no interim close: the close is owed, asked by next as a run issue, and closed here by hand
gh pr ready "$P" -R $R; gh pr merge "$P" -R $R --merge --match-head-commit "$H" --body 'Role: MR' > /dev/null; rd step; ok "^merged $P"; [ "$(cat "$T/gh/issues/1/state")" = CLOSED ] || fail 'the ticket stayed open'; ! grep -q '^closed S01' .vid/tw/handed || fail 'an interim close'; ok '^close S01$'; rd step; no '^merged'
rd next; ok '^asked [0-9]* close S01$'; C1=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/out"); rd step; no '^stop stray'; no '^error'; no '^close-again'; echo CLOSED > "$T/gh/issues/$C1/state"; tw_hand 'closed S01'
tw_hand 'candidate 0'; tw_hand 'staged 0'; : > "$T/nopost"; rd next; [ "$RC" = 1 ] && grep -q '^error post' "$T/out" || fail 'a failed post was no error'; rm "$T/nopost"; rd next; ok '^published'; N=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out" | head -n 1); N2=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out" | sed -n 2p); [ -n "$N2" ] || fail 'S02 and S03 did not both go out'; grep -q "^- base: $(git -C "$T/code.git" rev-parse main)" ".vid/tw/out/issue-$N.md" || fail "the base is not main after the merge"
# a re-plan reaches a published ticket through next, and a saved ticket's second writing
pt_rs 's/^\(step S02 .*\)ROW-012 /\1/'; pt_rs 's/^\(step S04 .*rows: \)/\1ROW-012 /'; sh "$CHECKS/plan.sh" change rows 'ROW-012 waits for S04' --trigger scope-change --evidence "ticket:$N" --expect 'S02 ships without it' > "$T/out" 2>&1 || fail 'the plan change was refused'; tw_ratify 'Yes, again'; rd next; ok "^amended $N$"; rd next; no '^amended'
# a blocked question beside a ticket that goes on; a held row with nothing answered; a second report holds it
H2=$(br ticket-$N2); P2=$(pr ticket-$N2 "$N2"); h2=$(printf %s "$H2" | cut -c1-12); rows=$(sed -n 's/^- rows: //p' ".vid/tw/out/issue-$N2.md"); C=''; for r in $rows; do C="$C $r=pass"; done
printf 'TA: stops\n' > "$T/c"; gh issue comment "$N" -R $R --body-file "$T/c" > /dev/null; gh issue edit "$N" -R $R --add-label blocked; rep "pr-$P2-$h2-1" "$H2" $C; ask "$P2" "$H2"; rd step; ok "^question $N$"; ok "^decided $P2"; [ "$(cat "$T/gh/issues/$N/comments/$(ls "$T/gh/issues/$N/comments" | sort -n | tail -n 1)")" = 'TA: stops' ] || fail 'a blocked question was answered'
gh issue edit "$N" -R $R --remove-label blocked; rep "pr-$P2-$h2-2" "$H2" $C; ask "$P2" "$H2"; rd step; ok '^held '; [ ! -s .vid/decide/rulings ] && [ ! -f .vid/tw/stood-in-answers.txt ] || fail 'a held row was answered with the switch off'
# a person's rule: no new ask, and the next step decides that head again
Ro=$(sed -n 's/^held //p' "$T/out" | head -n 1); [ -n "$Ro" ] || fail 'no held row'; n0=$(ls "$T/gh/prs/$P2/comments" | wc -l); sh "$DS" rule "$Ro" limit > /dev/null; rd step; [ "$(ls "$T/gh/prs/$P2/comments" | wc -l)" -gt "$n0" ] && grep -q "^$Ro known limit" "$T/gh/prs/$P2/comments/$(ls "$T/gh/prs/$P2/comments" | sort -n | tail -n 1)" || fail "a person's rule was not decided"; rd step; no '^decided'
# a question labelled on the pull request reaches the round
printf 'blocked\n' > "$T/gh/prs/$P2/labels"; rd step; ok "^question $P2$"; printf '' > "$T/gh/prs/$P2/labels"
# the switch: a held row with its evidence missing accepted, labelled; a held product failure answered by nothing
printf 'stand-in: on\n' >> .vid/tw/settings; ask "$P2" "$H2"; rd step; grep -q 'accept' .vid/tw/stood-in-answers.txt && grep -q 'stand-in' .vid/decide/rulings || fail 'the switch did not answer'; last=$(ls "$T/gh/prs/$P2/comments" | sort -n | tail -n 1); grep -q 'accepted by ruling' "$T/gh/prs/$P2/comments/$last" || fail 'the switch reached no decision'
H3=$(br ticket-$N); P3=$(pr ticket-$N "$N"); h3=$(printf %s "$H3" | cut -c1-12); rep "pr-$P3-$h3-1" "$H3" ROW-001=fail:broke; ask "$P3" "$H3"; rd step; H4=$(br ticket-$N); h4=$(printf %s "$H4" | cut -c1-12); rep "pr-$P3-$h4-1" "$H4" ROW-001=fail:broke; ask "$P3" "$H4"; c0=$(wc -l < .vid/tw/stood-in-answers.txt); rd step; ok '^held ROW-001'; [ "$(wc -l < .vid/tw/stood-in-answers.txt)" = "$c0" ] || fail 'the table answered a held product failure'
sed -i.b '/^stand-in: on$/d' .vid/tw/settings; rm -f .vid/tw/settings.b
# the alarms, each once until it clears; incidents on the progress line
sed -i.b "s/^\(published $N .*\) at=.*/\1 at=2020-01-01T00:00:00Z/" .vid/tw/log; rm -f .vid/tw/log.b; echo 2020-01-01T00:00:00Z > "$T/gh/issues/$N/updated"; echo 2020-01-01T00:00:00Z > "$T/gh/prs/$P3/updated"; printf '%s 90\n' "$(date +%s)" >> .vid/decide/accepted-log; rd step; ok "^flag ticket-hours $N"; ok "^flag ticket-quiet $N"; ok '^flag row-drop'; ok 'incidents=[1-9]'; rd step; no '^flag'; grep -q "word=ticket-hours on=$N" .vid/metrics-events && grep -q "FLAG ticket-quiet $N" .vid/HEARTBEAT.md || fail 'no flag event or heartbeat line'
rm "$T/gh/issues/$N/updated" "$T/gh/prs/$P3/updated"; rd step; grep -q "flag-cleared word=ticket-quiet on=$N" .vid/metrics-events || fail 'a flag did not clear'
# one read a tick: 4 calls
: > "$T/gh/log"; sh "$GS" round-read > /dev/null; [ "$(wc -l < "$T/gh/log" | tr -d ' ')" = 4 ] || { cat "$T/gh/log" > "$T/out"; fail 'round-read is not 4 calls'; }
# wait: timeout; new on a new ask, and ViD's own post ends no wait; a lost lock writes nothing; a pause publishes nothing
VID_WAIT_TICK=1 VID_WAIT_MAX=1 rd wait; ok '^timeout$'; ask "$P2" "$H2"; VID_WAIT_TICK=1 VID_WAIT_MAX=5 rd wait; ok '^new$'; rd step; VID_WAIT_TICK=1 VID_WAIT_MAX=1 rd wait; ok '^timeout$'
# a failed call during a renew is an error that names its step, not a lost lock; the next step clears it
mv "$SR" "$SR.gone"; rd step; [ "$RC" = 1 ] && ok '^error lock-renew' || fail 'a failed renew was read as a lost lock'; mv "$SR.gone" "$SR"; rd step; [ "$RC" = 0 ] || fail 'a blip did not clear'
M=$(cat .vid/lock-session); echo other > .vid/lock-session; c=$(git -C "$SR" rev-parse refs/heads/vid-state/records); rd step; [ "$RC" = 3 ] && grep -qx lock-lost "$T/out" || fail 'a lost lock went on'; rd next; [ "$RC" = 3 ] || fail 'next went on with a lost lock'; [ "$(git -C "$SR" rev-parse refs/heads/vid-state/records)" = "$c" ] || fail 'a lost lock wrote'; echo "$M" > .vid/lock-session
sed -i.b 's/^run:.*/run: stopped owner asked to pause/' .vid/RUN-STATE.md; rm -f .vid/RUN-STATE.md.b; rd next; ok 'nothing is published'; sed -i.b 's/^run:.*/run: active/' .vid/RUN-STATE.md; rm -f .vid/RUN-STATE.md.b
# nothing-left: no ticket open, and each step started or refused
# v0.26.10.27.3: withdrawn by ViD first (a plant, as a plan change writes it), so the round does not read them as closed outside (8.1b R1)
for x in "$N" "$N2"; do printf 'withdrawn %s decision=self-test at=2026-11-10T00:00:00Z\n' "$x" >> .vid/tw/log; done
gh issue close "$N" -R $R; gh issue close "$N2" -R $R; for p in "$P2" "$P3"; do echo CLOSED > "$T/gh/prs/$p/state"; done; rd next; rd step; ok '^nothing-left$'
# v0.26.10.27.2: an owner's grade ask out holds nothing-left back; lost, it waits on the owner and holds nothing
{ grep -v '^close-wait-minutes:' .vid/tw/settings; echo 'close-wait-minutes: 600'; } > "$T/st"; cat "$T/st" > .vid/tw/settings
sh "$CHECKS/grade.sh" ask > "$T/out" 2>&1 || fail "the grade ask failed: $(cat "$T/out")"; GK=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out"); rd step; ! grep -q '^nothing-left$' "$T/out" || fail 'nothing-left with a grade ask out'
{ grep -v '^close-wait-minutes:' .vid/tw/settings; echo 'close-wait-minutes: 0'; } > "$T/st"; cat "$T/st" > .vid/tw/settings; rd step; ok "^grade-again $GK$"; rd step; ok "^grade-lost $GK$"; rd step; ok '^nothing-left$'
if [ -d "$CHECKS/../skills/vid-run" ]; then F=$CHECKS/../skills/vid-run/SKILL.md; for l in 'The only stops' '**You never:**' 'vid-connect' 'round.sh wait' 'round.sh next' 'plan.sh change' 'restart a session'; do grep -qF -- "$l" "$F" || fail "vid-run lacks: $l"; done; for l in 'state-restore' 'lock-take' 'observe.sh start' 'mode: tickets'; do grep -qF -- "$l" "$CHECKS/../skills/vid-connect/SKILL.md" || fail "vid-connect lacks: $l"; done; grep -qF '/vid:vid-run' "$CHECKS/../skills/vid-help/SKILL.md" && grep -qF '/vid run' "$CHECKS/../skills/vid-add/SKILL.md" || fail 'help or add does not name the verb'; fi
exit 0
