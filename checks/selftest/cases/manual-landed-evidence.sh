#!/bin/sh
# Purpose: selftest case — a test's evidence counted from the amendment that adds or restates it (GM-4 E3, GM M5), in GitHub manual, on
# the toy and the fake gh (fixtures/accept.sh), by results.sh read --ticket <n> --at <c> and decide.sh. The ticket's newest `amended`
# log line restates ROW-012 and adds ROW-020 (a top-up, or a team-added test taken in: the same added= list). Before any report made
# after it: ROW-012's and ROW-020's red runs before it do not count, nor results made before it; ROW-001, whose landed change the
# ticket does not quote, keeps its evidence from the publication. With no case since the amendment it is `missing`, counted toward no hold;
# failing at two commits after it, ROW-012 is held, a Q line in RUN-STATE, though a landing names it, and still after a switch to GitHub auto. After it: a red run and a head report made later count for both. A taken-over ticket's row restated by its first
# amendment, with no landing on the log: only its later red run counts. A pass a decision before the amendment read is not carried past it. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-landed-evidence: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
row() { awk -F'\t' -v r="$1" '$1 == r { print $3 " " $4; exit }' "$T/out"; }
rd() { sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; sh "$CHECKS/results.sh" read --ticket "$1" --at "$2" > "$T/out" 2>&1 || fail "the read at $2 failed"; }
ac_project "$T/p" || fail 'the toy could not be made'
{ mn_ticket "$AC_N" S02 step ROW-001 ROW-012 ROW-020; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"
printf 'landed draft=1 ids=ROW-001 at=2026-11-18T12:00:00Z\namended %s kind=step step=S02 rows=ROW-001,ROW-012,ROW-020 parts=2 at=2026-11-19T12:00:00Z added=ROW-020 words="yes" restated=ROW-012\n' "$AC_N" >> .vid/tw/log
mkdir -p .vid/decide; printf 'ROW-012 1 2026-11-19T11:59:00Z\n' > .vid/decide/landed   # a landing names it, after the ticket's publication
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the read failed'
# before the amendment: a red run and two head reports
AC_WHEN='2026-11-19 10:00:00 +0000'; _i=red-$AC_N-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001 ROW-012 ROW-020' "$AC_RED")"
rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=fail:no ROW-012=fail:no ROW-020=fail:no)"; ac_send "$_i"
AC_WHEN='2026-11-19 11:00:00 +0000'; ac_head "$AC_C" 1 ROW-001=pass ROW-012=pass ROW-020=pass
tk_dev 'C2'; C2=$(git -C "$T/dev" rev-parse HEAD); AC_WHEN='2026-11-19 11:30:00 +0000'; ac_head "$C2" 1 ROW-001=pass ROW-012=pass ROW-020=pass
rd "$AC_N" "$AC_C"; [ "$(row ROW-001)" = 'red passed' ] || fail "ROW-001's evidence from the publication was dropped for a landing it does not quote: $(row ROW-001)"
[ "$(row ROW-012)" = 'n/a missing' ] || fail "ROW-012's red run or results before its restatement counted: $(row ROW-012)"
grep -q '^ROW-012	.*no case since its amendment' "$T/out" || fail 'the results before the restatement are not named as such'
[ "$(row ROW-020)" = 'n/a missing' ] || fail "ROW-020's evidence before the top-up counted: $(row ROW-020)"
sh "$CHECKS/decide.sh" decide --ticket "$AC_N" --at "$AC_C" > "$T/out" 2>&1 || fail 'the decision at C failed'
rd "$AC_N" "$C2"; sh "$CHECKS/decide.sh" decide --ticket "$AC_N" --at "$C2" > "$T/out" 2>&1 || fail 'the decision at C2 failed'; grep -q '^ROW-012 evidence missing' "$T/out" && ! grep -q '^ROW-012 ' .vid/decide/counts || fail 'a row with no case since its amendment is held, or counted'
# failing in results made after it, at two commits: held
AC_WHEN='2026-11-19 12:30:00 +0000'; for c in "$AC_C" "$C2"; do ac_head "$c" 2 ROW-001=pass ROW-012=fail:no ROW-020=pass; rd "$AC_N" "$c"; sh "$CHECKS/decide.sh" decide --ticket "$AC_N" --at "$c" > "$T/out" 2>&1 || fail 'a decision failed'; done; sh "$CHECKS/decide.sh" decide --ticket "$AC_N" --at "$C2" > "$T/out" 2>&1 || fail 'the decision at C2 failed'; grep -q '^ROW-012 held' "$T/out" || fail 'ROW-012 is not held at C2'
sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'the queue did not sync'; grep -q 'held ROW-012' .vid/RUN-STATE.md || { cp .vid/RUN-STATE.md "$T/out"; fail 'the held restated row is no Q line'; }
cp .vid/plan/setup "$T/setup0"; printf 'setup-answered key=github-mode value="auto" words="auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'the queue did not sync in GitHub auto'; grep -q 'held ROW-012' .vid/RUN-STATE.md || { cp .vid/RUN-STATE.md "$T/out"; fail "after the switch to auto the held row of a ticket's decision is dropped for its landing"; }
cp "$T/setup0" .vid/plan/setup
# after the amendment: a red run and a head report count
AC_WHEN='2026-11-19 13:00:00 +0000'; _i=red-$AC_N-2; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-012 ROW-020' "$AC_RED")"
rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-012=fail:no ROW-020=fail:no)"; ac_send "$_i"
tk_dev 'C3'; C3=$(git -C "$T/dev" rev-parse HEAD); AC_WHEN='2026-11-19 13:30:00 +0000'; ac_head "$C3" 1 ROW-001=pass ROW-012=pass ROW-020=pass
rd "$AC_N" "$C3"; [ "$(row ROW-012)" = 'red passed' ] || fail "ROW-012's evidence after its restatement was dropped: $(row ROW-012)"
[ "$(row ROW-020)" = 'red passed' ] || fail "the topped-up ROW-020 did not read its later reports: $(row ROW-020)"
# a taken-over ticket, its row restated by its first amendment, no landing on the log
N2=$(gh_issue 'Step S03'); { mn_ticket "$N2" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"
printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z taken-over=1\namended %s kind=step step=S03 rows=ROW-006 parts=2 at=2026-11-19T12:00:00Z added=- words="yes" restated=ROW-006\n' "$N2" "$N2" >> .vid/tw/log
AC_WHEN='2026-11-19 10:00:00 +0000'; _i=red-$N2-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-006' "$AC_RED")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-006=fail:no)"; ac_send "$_i"
AC_WHEN='2026-11-19 13:30:00 +0000'; _i=step-$N2-$(printf %s "$C3" | cut -c1-12)-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha' "$C3")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-006=pass)"; ac_send "$_i"
rd "$N2" "$C3"; [ "$(row ROW-006)" = 'n/a passed' ] || fail "the taken-over ticket's red run before its first amendment counted: $(row ROW-006)"
AC_WHEN='2026-11-19 13:00:00 +0000'; _i=red-$N2-2; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-006' "$AC_RED")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-006=fail:no)"; ac_send "$_i"
rd "$N2" "$C3"; [ "$(row ROW-006)" = 'red passed' ] || fail "the taken-over ticket's later red run did not count: $(row ROW-006)"
# a pass a decision before the amendment read is not carried past it: ROW-010 accepted at C, then restated; at C4 a report made before the
# amendment alone leaves it missing, and one made after it counts
N3=$(gh_issue 'Step S04'); { mn_ticket "$N3" S04 step ROW-010; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N3.md"
printf 'published %s kind=step step=S04 rows=ROW-010 at=2026-11-18T09:00:00Z\n' "$N3" >> .vid/tw/log; dc() { rd "$N3" "$1"; sh "$CHECKS/decide.sh" decide --ticket "$N3" --at "$1" > "$T/out" 2>&1 || fail "the decision of ROW-010 at $1 failed"; }
AC_WHEN='2026-11-19 10:00:00 +0000'; ac_report run-10 'A. Person' "$AC_C" 'r.xml=ROW-010=pass'; dc "$AC_C"; grep -q '^ROW-010 accepted' "$T/out" || fail 'ROW-010 is not accepted on its results at C'
printf 'amended %s kind=step step=S04 rows=ROW-010 parts=2 at=2026-11-20T12:00:00Z added=- words="yes" restated=ROW-010\n' "$N3" >> .vid/tw/log
tk_dev 'C4'; C4=$(git -C "$T/dev" rev-parse HEAD); ac_report run-11 'A. Person' "$C4" 'r.xml=ROW-010=pass'; dc "$C4"
! grep -q '^ROW-010 accepted' "$T/out" && grep -q '^ROW-010 evidence missing' "$T/out" || fail "ROW-010's pass from before its amendment was carried past it"
AC_WHEN='2026-11-20 13:00:00 +0000'; ac_report run-12 'A. Person' "$C4" 'r.xml=ROW-010=pass'; dc "$C4"; grep -q '^ROW-010 accepted' "$T/out" || fail 'results made after the amendment did not count'
exit 0
