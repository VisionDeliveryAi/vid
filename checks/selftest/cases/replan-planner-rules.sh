#!/bin/sh
# Purpose: selftest case — a plan change in the run is held to ticket mode's plan rules (0.26.10.29.2, R1). On the
# planner's toy at `stage name=run`, rule A's ceiling at 11 or 12: `plan.sh change` that makes S02 13 rows is refused,
# its added flag `size S02` printed, a decision kept with result=refused and the recorded hash unchanged, while flags
# the recorded plan already had (S03 over 11, a standing line missing from PLAN.md) block nothing; a merge into S02
# that names its own raise (`other`, unverified-rows=20) is accepted where the same merge without it is refused; the
# same breach in /vid plan's session (`stage name=plan`) is accepted, and develop's change never calls planner.sh;
# a change that leaves S02's failing row ROW-001 (started; its inventory test an `owed:` line, which develop's orphan
# guard reads as owed) in no step is refused for P3's flag. Flags compared line by line, counted (a size flag by
# its step, a needs flag less its step): a change that shrinks a flagged step and moves a flagged row is accepted; one
# that grows a flagged step, repeats a flag or trades one for another breach of its row is refused; a raise counts for
# rows added to a started step too. Each section reports its own failure. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "replan-planner-rules: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
# toy <ceiling> [plan]: a fresh toy, the run's stage started (unless plan), .vid/budget at that ceiling
toy() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; printf 'stacks=1\nunverified-rows=%s\n' "$1" > .vid/budget
  [ "${2:-}" = plan ] || echo 'stage name=run state=start session=S1 records=29 at=2026-11-03T10:00:00Z' >> .vid/metrics-events; }
ch() { RC=0; sh "${PS:-$CHECKS/plan.sh}" change "$@" > "$T/out" 2>&1 || RC=$?; }
hashes() { grep -c '^plan-change ' .vid/metrics-events; }
# grow: ROW-002 and HOS-003 move from S04 into S02, which then holds 13 rows
grow() { pt_rs 's/^\(step S02 .* RULE-005\) |/\1 ROW-002 HOS-003 |/; s/^\(step S04 .*rows: \)ROW-002 \(.*\) HOS-003 \(.*\)$/\1\2 \3/'; }
refusedok() { [ "$RC" = 1 ] || fail "$1: the change was not refused (exit $RC)"; [ "$(hashes)" = "$2" ] || fail "$1: a refused change recorded a plan hash"
  d=$(ls -t .vid/plans/decisions/*.why | head -n 1); grep -qx 'result=refused' "$d" || fail "$1: no decision with result=refused"; }
BAD=0; sec() { ( "$@" ) || BAD=1; }

s1() { toy 11; grep -v '^standing work ' PLAN.md > P.x && mv P.x PLAN.md
  sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 && fail 'the toy at a ceiling of 11 with no standing work line is clean'
  grep -q '^size S03 ' "$T/out" && grep -q '^standing work ' "$T/out" || fail 'the toy lacks its two standing flags'
  pt_rs 's/name: synonym-aware search/name: search by other names/'; n=$(hashes)
  ch other 'S05 renamed' --trigger discovered-dependency --evidence step:S05 --expect 'the same rows'
  [ "$RC" = 0 ] || fail "a change adding no flag was refused for flags the recorded plan had (exit $RC)"
  grow; n=$(hashes); ch rows 'the cap moves into S02' --trigger discovered-dependency --evidence step:S02 --expect 'S02 holds the cap'
  refusedok 'a size breach' "$n"
  grep -q 'size S02 — 13 rows, over the ceiling of 11' "$T/out" || fail 'the refusal does not print the flag the change adds'
  ! grep -q 'size S03\|standing work' "$T/out" || fail "the refusal names a flag the recorded plan had"
  grep -q '^refusal=.*refused' "$(ls -t .vid/plans/decisions/*.why | head -n 1)" || fail 'the decision keeps no refusal line'; }

s2() { toy 12; pt_rs '/^step S04 /d; s/^\(step S02 .* RULE-005\) |/\1 ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 |/'; n=$(hashes)
  ch merge 'S04 into S02' --trigger cost --evidence step:S02 --expect 'one ticket'
  refusedok 'a merge over the ceiling with no raise' "$n"
  ch other 'S04 into S02, one ticket; unverified-rows=20' --trigger cost --evidence step:S02 --expect 'one ticket'
  [ "$RC" = 0 ] || fail "a merge naming its own raise was refused (exit $RC)"
  grep -qx 'unverified-rows=20' .vid/budget || fail 'the raise is not in .vid/budget'
  sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 || fail 'planner.sh check flags the merged plan after its raise'; }

s3() { toy 12 plan; grow; n=$(hashes)
  ch rows 'the cap moves into S02' --trigger discovered-dependency --evidence step:S02 --expect 'S02 holds the cap'
  [ "$RC" = 0 ] || fail "/vid plan's session refused a change for a planner flag (exit $RC)"
  sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 && fail 'the grown S02 is not flagged'
  # develop's change: a copy of checks/ whose planner.sh leaves a mark; a develop run's change never calls it
  rm -rf "$T/ck"; cp -R "$CHECKS" "$T/ck"; mv "$T/ck/planner.sh" "$T/ck/planner-real.sh"
  printf '#!/bin/sh\necho called >> "%s/called"\nexec sh "$(dirname "$0")/planner-real.sh" "$@"\n' "$T" > "$T/ck/planner.sh"
  toy 12 plan; awk '/^```vid-plan/ { print; print "step S01 | name: a | modules: web | builds-on: - | rows: ROW-003 ROW-004"; print "step S02 | name: b | modules: digest | builds-on: S01 | rows: ROW-001"; print "shared: web"; s = 1; next }
    s && /^```/ { s = 0 } !s && !/^mode: /' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md   # a develop run: no mode line, a block in develop's grammar
  echo 'stage name=develop state=start session=S1 at=2026-11-03T10:00:00Z' >> .vid/metrics-events
  rm -f "$T/called"; PS=$T/ck/plan.sh ch other 'a develop plan' --trigger discovered-dependency --evidence step:S02 --expect 'the same rows'
  [ "$RC" = 0 ] || fail "develop's change was refused (exit $RC)"; [ ! -f "$T/called" ] || fail "develop's plan.sh change called planner.sh"
  toy 12; rm -f "$T/called"; PS=$T/ck/plan.sh ch other 'S05 renamed' --trigger discovered-dependency --evidence step:S05 --expect 'the same rows'
  [ -f "$T/called" ] || fail "the run's plan.sh change did not call planner.sh"; }

s5() { toy 12; cp -R "$CHECKS" checks   # develop's orphan guard reads checks/evidence.sh at the home, at HEAD
  git init -q . && git add -A . && git -c user.name=t -c user.email=t@t commit -qm toy || fail 'the toy could not be committed'
  P=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1)
  echo "step-start step=S02 plan=$P base=nohead at=2026-11-03T11:00:00Z" >> .vid/metrics-events
  mkdir -p .vid/tw; printf 'closed S01 | stand-in: C1 #1 at abc\nrow ROW-001 failing | stand-in: C1 #2 at abc\n' > .vid/tw/handed
  pt_rs 's/^\(step S02 .*rows: \)ROW-001 /\1/; s/^needs ROW-001 /needs /'; n=$(hashes)
  ch drop 'ROW-001 out of S02' --trigger scope-change --evidence step:S02 --expect 'S02 without its first row'
  refusedok "a change leaving a started step's failing row in no step" "$n"
  grep -q 'class ROW-001 — in no step' "$T/out" || fail 'the refusal does not name P3 for ROW-001'; }

# flags compared line by line, counted; a size flag is its step's, added only when the step grew; a needs flag less its step
runon() { echo 'stage name=run state=start session=S1 records=29 at=2026-11-03T10:00:00Z' >> .vid/metrics-events; }
s6() { toy 10 plan; pt_rs 's/^\(needs ROW-006 ROW-007 ROW-010 ROW-014\) ROW-019 /\1 /'; pt_record; runon
  sh "$CHECKS/planner.sh" check > "$T/out" 2>&1; grep -q '^size S03 — 12 rows' "$T/out" && grep -q '^needs ROW-019 — in step S03' "$T/out" || fail 'the recorded toy lacks its size S03 and needs ROW-019 flags'
  pt_rs 's/^\(step S03 .*\) ROW-019 /\1 /; s/^\(step S04 .* RULE-004\) |/\1 ROW-019 |/'
  ch rows 'ROW-019 into S04' --trigger discovered-dependency --evidence step:S04 --expect 'S03 smaller'
  [ "$RC" = 0 ] || fail "a change that shrinks a flagged step and moves a flagged row was refused (exit $RC)"
  pt_rs 's/^\(step S03 .* HOS-005\) |/\1 ROW-002 |/; s/^\(step S04 .*rows: \)ROW-002 /\1/'; n=$(hashes)
  ch rows 'ROW-002 into S03' --trigger discovered-dependency --evidence step:S03 --expect 'S03 holds the cap'
  refusedok 'a flagged step that grew' "$n"; grep -q 'size S03 — 12 rows, over the ceiling of 10' "$T/out" || fail 'the refusal does not name the grown size flag'; }
s7() { toy 12 plan; ins() { awk '/^shared: web$/ { print "needs ROW-017 | -" } { print }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; }
  ins; pt_record; runon; sh "$CHECKS/planner.sh" check > "$T/out" 2>&1; [ "$(grep -c '^needs ROW-017 ' "$T/out")" = 1 ] || fail 'the recorded toy does not flag ROW-017 once'
  ins; n=$(hashes); ch other 'ROW-017 in a third needs line' --trigger discovered-dependency --evidence step:S05 --expect 'the same rows'
  refusedok 'a flag repeated over the recorded plan' "$n"; }
s8() { toy 12; P=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1)
  echo "step-start step=S02 plan=$P base=nohead at=2026-11-03T11:00:00Z" >> .vid/metrics-events
  mkdir -p .vid/tw; printf 'closed S01 | stand-in: C1\nrow ROW-003 accepted | stand-in: C1\nrow ROW-004 accepted | stand-in: C1\n' > .vid/tw/handed
  grow; ch other 'S02 holds the cap; unverified-rows=20' --trigger cost --evidence step:S02 --expect 'S02 at 13 rows'
  [ "$RC" = 0 ] || fail "a change raising its own ceiling for rows added to a started step was refused (exit $RC)"; }

# a flag is never traded for another breach of the same row: ROW-019 out of every needs line recorded, then needing S05
s9() { toy 12 plan; pt_rs 's/^\(needs ROW-006 ROW-007 ROW-010 ROW-014\) ROW-019 /\1 /'; pt_record; runon
  awk '/^shared: web$/ { print "needs ROW-019 | S05" } { print }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; n=$(hashes)
  ch other 'ROW-019 needs S05' --trigger discovered-dependency --evidence step:S05 --expect 'ROW-019 waits for S05'
  refusedok 'a needs flag traded for another breach of the same row' "$n"; grep -q 'needs ROW-019 — needs S05' "$T/out" || fail 'the refusal does not name the new needs breach'; }

sec s1; sec s2; sec s3; sec s5; sec s6; sec s7; sec s8; sec s9
exit $BAD
