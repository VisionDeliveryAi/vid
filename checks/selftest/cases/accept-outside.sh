#!/bin/sh
# Purpose: selftest case — a ticket accepted outside ViD is recorded by the owner's words (FB-3 A4): round.sh accept <n> <commit> --outside
# "<words>" and decide.sh outside, on GitHub manual's toy and the fake gh (fixtures/accept.sh). With no results the ticket's decision is
# refused, its line ending with the command. The record is refused, and nothing written, with no words, at a commit off main, with no
# commit, and for a ticket not published, withdrawn or accepted. With them: each row of the ticket, and each transition of its journey,
# accepted by ruling in rulings, state and the handed record, its label the owner's words, ending that there is no evidence (FB-3 E1); a deploy-owed one owed, with no ruling; a known
# limit and one accepted already left, and said; each on the record; the merges, merged-prs and accepted-at lines; one event; nothing
# posted. plan.sh warnings counts those rows no more; the ticket is not open; `close.sh owed` names its step; the team's unanswered ask
# is answered `accepted at <c12>`, once. A restore brings the record back, and the next ask the same answer. A later failing run of a row
# undoes it. A row held at its second failure, recorded: no count, no halt, no place on the queue page and no Q line of it stands. In GitHub auto, a ticket whose pull request merged with no decision is recorded at its merge commit. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-outside: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'; c12=$(printf %s "$AC_C" | cut -c1-12); D=.vid/decide; W='accepted before this, by our own team'
gh_w0() { find .vid/decide .vid/tw -type f ! -path '*/tmp.*' -exec cksum {} + | grep -vE '/(unit-merges|unit-asks|merged-prs|refused|flags|accepted-log)$' | sort | cksum; }
issue() { { mn_ticket "$@"; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$1.md"; _n=$1; _s=$2; _k=$3; shift 3; printf 'published %s kind=%s step=%s rows=%s at=2026-11-18T09:00:00Z\n' "$_n" "$_k" "$_s" "$(echo $* | tr ' ' ,)" >> .vid/tw/log; }
# the ticket: a journey, a plain row, a staging-owed one, a known limit and one accepted already
issue "$AC_N" S02 step ROW-001 ROW-004 ROW-010 ROW-012 ROW-013
printf 'row ROW-012 known-limit | stand-in: decision\nrow ROW-013 accepted | stand-in: decision\nengines alpha | stand-in: owner at 2026-11-18T09:00:00Z, words "alpha"\n' >> .vid/tw/handed
ac_round accept "$AC_N" "$AC_C"; grep -qxF "refused #$AC_N no results at $c12; accepted outside ViD: /vid:vid-accept-step $AC_N $c12 accepted \"<your words>\"" "$T/out" || fail 'the refusal does not name the command'
ac_round accept "$AC_N"; grep -qxF "refused #$AC_N no results on main; accepted outside ViD: /vid:vid-accept-step $AC_N <commit> accepted \"<your words>\"" "$T/out" || fail 'the refusal with no commit named does not name the command'
ac_ask "$AC_C"; c0=$(ac_comments)
# each refusal, and nothing written
N2=$(gh_issue 'Step S03'); issue "$N2" S03 step ROW-006; printf 'withdrawn %s decision=abc at=2026-11-19T09:00:00Z\n' "$N2" >> .vid/tw/log; w0=$(gh_w0)
no() { _w=$1; shift; ac_round accept "$@"; grep -q "^refused .*$_w" "$T/out" && [ "$(gh_w0)" = "$w0" ] || fail "not refused ($_w), or something was written: $*"; }
no 'words' "$AC_N" "$AC_C" --outside ''; no 'words' "$AC_N" "$AC_C" --outside '  '; no 'is not on main' "$AC_N" "$AC_OFF" --outside "$W"; no 'no published ticket' "$N2" "$AC_C" --outside "$W"; no 'no published ticket' 999 "$AC_C" --outside "$W"
ac_round accept "$AC_N" --outside "$W"; [ "$RC" = 2 ] && [ "$(gh_w0)" = "$w0" ] || fail "with no commit: exit $RC"
warn() { sh "$CHECKS/plan.sh" warnings S05 2> "$T/out" | grep 'not yet accepted' | sed 's/.*whose \([0-9]*\) tests are not.*/\1/' | head -n 1; }
b=$(warn); [ -n "$b" ] || fail 'the stage-ahead warning counts nothing on the toy'
ac_round accept "$AC_N" "$AC_C" --outside "$W"; [ "$RC" = 0 ] && grep -qx "accepted #$AC_N $c12, outside ViD, by the owner's words" "$T/out" || fail "the record: exit $RC"
grep -qx 'left ROW-012: a known limit' "$T/out" && grep -qx 'left ROW-013: accepted already' "$T/out" || fail 'a known limit or an accepted row is not said as left'
[ "$(ac_comments)" = "$c0" ] || fail 'the record posted'
for r in ROW-001 ROW-004; do grep -q "^row $r accepted-by-ruling | stand-in: owner at [0-9TZ:-]*, words \"$W\"; evidence: none, accepted outside ViD\$" .vid/tw/handed || { cat .vid/tw/handed >&2; fail "$r is not accepted by ruling on the handed record"; }; done
for r in ROW-001 ROW-004 ROW-004-T1 ROW-004-T3; do awk -F'\t' -v r="$r" -v w="$W" '$2 == r && $3 == "accept" && $4 == w && $5 == "owner" { f = 1 } END { exit !f }' $D/rulings || fail "$r has no ruling of the owner's"; done
for r in ROW-001 ROW-004-T1 ROW-004-T3; do awk -F'\t' -v r="$r" -v p="step-$AC_N" '$1 == r && $2 == "accepted by ruling" && $4 == p { f = 1 } END { exit !f }' $D/state || fail "$r's state is not accepted by ruling"; done
grep -q '^row ROW-010 owed ' .vid/tw/handed && ! grep -q 'ROW-010.accept' $D/rulings && awk -F'\t' '$1 == "ROW-010" && $2 == "owed" { f = 1 } END { exit !f }' $D/state || fail 'the staging-owed row is not owed, with no ruling'
grep -q '^row ROW-012 known-limit ' .vid/tw/handed && grep -qx 'row ROW-013 accepted | stand-in: decision' .vid/tw/handed && ! grep -qE 'ROW-01[23]' $D/rulings || fail 'a known limit or an accepted row was changed'
for r in ROW-001 ROW-004 ROW-010; do grep -qx "$r" $D/record || fail "$r is not on the record"; done
grep -qx "$(printf 'step-%s-%s\t%s\t%s\t%s' "$AC_N" "$c12" "$AC_N" "$AC_C" "$AC_C")" $D/merges && grep -qx "step-$AC_N-$c12" $D/merged-prs && grep -q "^step-$AC_N $AC_N $c12 at=" $D/accepted-at || fail 'the merge lines are not there'
[ "$(grep -c "^accepted-outside .*ticket=$AC_N .*rows=ROW-001,ROW-004,ROW-010 commit=$c12 words=\"$W\"" .vid/metrics-events)" = 1 ] || fail 'the event is not there, once'
a=$(warn); [ "${a:-0}" -lt "$b" ] || fail "the warning still counts those rows: $b before, ${a:-0} after"
sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; grep -qx 'close S02' "$T/out" || fail "its step's close is not owed"
w0=$(gh_w0); no 'accepted already' "$AC_N" "$AC_C" --outside "$W"
# the team's unanswered ask: answered by the next accept, once
ac_round step; grep -q "^decide #$AC_N $AC_C" "$T/out" || fail 'the unanswered ask is not told'; ac_round accept "$AC_N" "$AC_C"; grep -qx "accepted #$AC_N at $c12; its close runs there" "$T/out" && [ "$(ac_comments)" = $((c0 + 1)) ] || fail "the team's ask was not answered"
ac_last | grep -qx "ticket: accepted at $c12; its close runs there" || fail 'the answer is not the acceptance'
# restored: the same record, and the same answer to the next ask
cp .vid/tw/handed "$T/h0"; cp $D/merges "$T/m0"; cp $D/state "$T/s0"; cp $D/rulings "$T/r0"; sh "$CHECKS/github.sh" state-save > "$T/out" 2>&1 || fail 'the records could not be saved'
sh "$CHECKS/github.sh" lock-free > "$T/out" 2>&1 || fail 'the lock could not be freed'
rm -rf "$T/q"; git clone -q "$T/p" "$T/q"; cd "$T/q"; mkdir -p .vid/tw; cp -R "$T/p/.vid/tw/settings" .vid/tw/; sh "$CHECKS/github.sh" state-restore owner/vid-state > "$T/out" 2>&1 || { cd "$T/p"; fail 'the restore failed'; }
cmp -s "$T/h0" .vid/tw/handed && cmp -s "$T/m0" $D/merges && cmp -s "$T/s0" $D/state && cmp -s "$T/r0" $D/rulings || fail 'the restored record differs'
sh "$CHECKS/github.sh" lock-take ac > "$T/out" 2>&1 || fail 'no lock in the restored project'; ac_ask "$AC_RED"; ac_round accept "$AC_N" "$AC_RED"; grep -qx "accepted #$AC_N at $c12; its close runs there" "$T/out" || fail 'after a restore the next ask gets another answer'
# a later failing run undoes it: a second ticket with ROW-001 a regression row, red
N3=$(gh_issue 'Step S03'); { mn_ticket "$N3" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n\n## Regression rows\n\n- ROW-001\n\n'; } > ".vid/tw/out/issue-$N3.md"; printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$N3" >> .vid/tw/log
AC_N0=$AC_N; AC_N=$N3; ac_head "$AC_C" 1 ROW-006=pass ROW-001=fail:gone; ac_round accept "$N3" "$AC_C"; grep -q "^decided #$N3 $c12 ticket: not yet" "$T/out" || fail 'the second ticket was not decided'
grep -q '^row ROW-001 failing ' .vid/tw/handed && grep -q 'ROW-001.undone' $D/rulings || fail 'a later failing run did not undo it'
# a row held at its second failure (no shrink), its Q line on the owner's list: the record drops its counts, its halt, its place on the queue page and its Q line
NH=$(gh_issue 'Step S03 again'); issue "$NH" S03 step ROW-014; AC_N=$NH; for x in "$AC_RED" "$AC_C"; do ac_head "$x" 1 ROW-014=fail:gone; ac_round accept "$NH" "$x"; grep -q "^decided #$NH $(printf %.12s "$x") ticket: not yet" "$T/out" || fail "the held row's ticket was not decided at $x"; done
qline() { grep -E '^(- )?Q[0-9]+' .vid/RUN-STATE.md | grep -c 'held ROW-014 ' || true; }
grep -q '^ROW-014 ' $D/counts && awk -F'\t' '$2 == "ROW-014" { f = 1 } END { exit !f }' $D/halted && grep -qx '### ROW-014' $D/queue.md && [ "$(qline)" = 1 ] || { cat .vid/RUN-STATE.md $D/counts $D/halted > "$T/out"; fail 'the toy row is not counted, halted, on the queue page and a Q line'; }
ac_round accept "$NH" "$AC_C" --outside "$W"; grep -qx "accepted #$NH $c12, outside ViD, by the owner's words" "$T/out" || fail "the held row's ticket was not recorded"
[ "$(qline)" = 0 ] || fail "the held row's Q line stands after the record"
! grep -qx '### ROW-014' $D/queue.md || fail 'the held row is on the queue page after the record'
! grep -q '^ROW-014 ' $D/counts || fail "the held row's counts stand after the record"
! awk -F'\t' '$2 == "ROW-014" { f = 1 } END { exit !f }' $D/halted || fail "the held row's halt stands after the record"
# GitHub auto: merged with no decision, recorded at its merge commit
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
N4=$(gh_issue 'Step S04'); issue "$N4" S04 step ROW-002; ac_unit auto4 "$(printf 'ticket: #%s\n\nDecisions: none' "$N4")"; m12=$(printf %s "$AC_M" | cut -c1-12)
ac_round step; grep -q "^merged $AC_P, no decision" "$T/out" || fail 'the toy merge with no decision was not read so'; AC_N=$N4; c1=$(ac_comments)
ac_round accept "$N4" "$AC_M" --outside "$W"; [ "$RC" = 0 ] && grep -qx "accepted #$N4 $m12, outside ViD, by the owner's words" "$T/out" || fail "in GitHub auto: exit $RC"
grep -q '^row ROW-002 accepted-by-ruling ' .vid/tw/handed && grep -qx "step-$N4-$m12" $D/merged-prs && [ "$(ac_comments)" = "$c1" ] || fail 'in GitHub auto it is not recorded, or it posted'
exit 0
