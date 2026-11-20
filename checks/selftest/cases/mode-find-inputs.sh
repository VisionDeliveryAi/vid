#!/bin/sh
# Purpose: selftest case — the switch finds its own inputs (GM-3 S1, its case mode-find-inputs). On the fake gh, a toy project with
# two exports (the second after a commit that changes PRD.md alone, then one unchanged, after a commit of a file not exported), its plan block kept as .vid/plans/<hash>.plan and no RUN-STATE,
# and five issues: three published tickets labelled vid:ticket (#1 closed, #1 and #3 naming the first export, #2 the second), one
# team issue with no label, one labelled vid:ticket in the project's own form with no writing. Run with no input file and the
# export lines gone from the log, no copy of the spec repository and the export not on the spec repository, the switch asks for
# --applied alone, exit 5, the lock freed and nothing taken over. With the export on the spec repository again, it finds the applied
# commit from the newest export's message after a fetch (the second's, not the highest issue number's, nor the first's whose
# pushed line alone is in the log) and takes all three over, the
# plan from .vid/plans/ and PLAN.md from HEAD, each printed with where it came from before the tickets are taken over. With the
# export lines back and no applied version recorded, it finds it from the log line, and the mode is recorded. PLAN.md
# changed and not committed is refused, never overwritten (fix 6); the H is the export's pushed line's, never an unchanged one's
# (fix 1); a re-take with no input flag prints the recorded applied commit and RUN-STATE's plan with where each is recorded (fix 5); a list at its limit is read again, larger, and only past the cap
# is it a need. A failed read of the labelled issues or of the spec repository is a refusal to run
# again, never a need; every write of every run goes to the state repository alone (fix 4). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-find-inputs: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
# the two exports, as the ticket writer makes them (its subcommands run where RUN-STATE is; the switch finds none)
printf 'mode: tickets\n' > .vid/RUN-STATE.md
sh "$CHECKS/github.sh" spec-export > "$T/x" 2>&1 || { cat "$T/x" >&2; fail 'the first export failed'; }
X1=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log)
printf '\nOne line more, after the first export.\n' >> PRD.md; git commit -qam 'PRD.md: one line more'; H2=$(git rev-parse HEAD)
sh "$CHECKS/github.sh" spec-export > "$T/x" 2>&1 || { cat "$T/x" >&2; fail 'the second export failed'; }
X2=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log); [ -n "$X1" ] && [ -n "$X2" ] && [ "$X1" != "$X2" ] || fail 'the two exports are not two'
# a third export after a commit that changes no exported file: the log's `export <X2> from=<H3> state=unchanged`, which never names
# X2's H
printf 'notes\n' > NOTES.txt; git add NOTES.txt; git commit -qm 'NOTES.txt, not exported'; H3=$(git rev-parse HEAD)
sh "$CHECKS/github.sh" spec-export > "$T/x" 2>&1 || { cat "$T/x" >&2; fail 'the third export failed'; }
grep -q "^export $X2 from=$H3 state=unchanged " .vid/tw/log || fail 'the third export did not log an unchanged line for the second'
rm -f .vid/RUN-STATE.md
PH=$(git hash-object "$T/plan.blk" | cut -c1-12); mkdir -p .vid/plans; cp "$T/plan.blk" ".vid/plans/$PH.plan"
tick() { _x=$1; shift; mn_ticket "$@" | sed "s/^- plan: .*/- plan: $PH/; s/^- export: .*/- export: $_x/"; }
N1=$(gh_issue 'Skeleton'); tick "$X1" "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" comments 2; gh_attr "$N1" state CLOSED
N2=$(gh_issue 'Step S02'); tick "$X2" "$N2" S02 step ROW-001 ROW-005 ROW-008 > "$T/t2"; gh_writing "$N2" "$T/t2" body 3
N3=$(gh_issue 'Step S03'); tick "$X1" "$N3" S03 step ROW-006 ROW-007 > "$T/t3"; gh_writing "$N3" "$T/t3" comments 2
mn_body ROW-010 > "$T/b5"; N4=$(gh_issue 'A team issue'); N5=$(gh_issue 'Written by hand' "$T/b5")
for n in "$N1" "$N2" "$N3" "$N5"; do gh_attr "$n" labels vid:ticket; done
gh_wclear

# 0. PLAN.md changed and not committed, no --plan-md: refused, naming it, the file untouched
printf '\nAn edit not committed.\n' >> PLAN.md; cp PLAN.md "$T/pm-edit"
RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'PLAN.md has changes not committed: commit them, or name the file with --plan-md' "$T/mo" || fail "the switch with PLAN.md changed and not committed exited $RC, not refused naming it"
cmp -s PLAN.md "$T/pm-edit" || fail 'the switch overwrote the PLAN.md not committed'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the PLAN.md refusal'
git checkout -q -- PLAN.md

# 1. the export lines gone, no copy of the spec repository, and the spec repository's main gone: --applied alone is asked for
SR=$FAKEGH/repos/owner%code-spec/remote.git; SM=$(git --git-dir="$SR" rev-parse refs/heads/main); git --git-dir="$SR" update-ref -d refs/heads/main
grep '^export ' .vid/tw/log > "$T/xl"; grep -v '^export ' .vid/tw/log > "$T/lg" || :; cp "$T/lg" .vid/tw/log; rm -rf .vid/spec.git
# the list read with a limit of 2, so it is read again, larger, until it is whole
RC=0; VID_TICKETS_LIMIT=2 sh "$CHECKS/mode.sh" manual --review "$T/review" > "$T/mo" 2>&1 || RC=$?
grep -q '^found register 3 tickets' "$T/mo" || fail 'the list at its limit was not read again, larger, before it was a need'
[ "$RC" = 5 ] || fail "the switch run with no input file, no export line and no export on the spec repository exited $RC, not 5 (need --applied alone)"
[ "$(grep -c '^need ' "$T/mo")" = 1 ] && grep -q '^need --applied — .*spec repository' "$T/mo" || fail 'the switch did not ask for --applied alone, with where it looked'
grep 'refused' "$T/mo" | grep -q -- '--applied' || fail 'the refusal does not name --applied'
grep -q '^taken-over ' "$T/mo" && fail 'a ticket was taken over with an input not found'
[ ! -s .vid/tw/applied ] || fail 'an applied version was recorded on the refused run'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the refusal'
[ "$(sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS")" != manual ] || fail 'the refused switch recorded the mode'

# 1a. the same, with GitHub's list of the labelled issues failing (a wrapper ahead of the fake gh on PATH): a refusal to run again,
# never a need
mkdir -p "$T/wh"
printf '#!/bin/sh\ncase " $* " in *" issue list "*"--label vid:ticket "*) echo "HTTP 502: the read the case makes fail" >&2; exit 1 ;; esac\nexec "%s" "$@"\n' "$T/bin/gh" > "$T/wh/gh"; chmod +x "$T/wh/gh"
RC=0; PATH="$T/wh:$PATH" sh "$CHECKS/mode.sh" manual --review "$T/review" > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'the published tickets could not be read from GitHub .*run this again' "$T/mo" || fail "the switch with the labelled issues' list failing exited $RC, not refused to run again"
grep -q 'the read the case makes fail' "$T/mo" || fail "the refusal does not give GitHub's words"
grep -q '^need ' "$T/mo" && fail 'a failed read of the published tickets was asked of the owner'
grep -q '^taken-over ' "$T/mo" && fail 'a ticket was taken over after a failed read'
[ ! -s .vid/tw/applied ] || fail 'an applied version was recorded after a failed read'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the failed read of the published tickets'

# 1b. the same, with git's read of the spec repository failing (a wrapper ahead of git on PATH): a refusal to run again, with git's
# words, never a need
mkdir -p "$T/wg"; GR=$(command -v git)
printf '#!/bin/sh\nl=; s=; for a in "$@"; do case $a in ls-remote) l=1 ;; *code-spec*) s=1 ;; esac; done\n[ -z "$l" ] || [ -z "$s" ] || { echo "fatal: the read the case makes fail" >&2; exit 128; }\nexec "%s" "$@"\n' "$GR" > "$T/wg/git"; chmod +x "$T/wg/git"
RC=0; PATH="$T/wg:$PATH" sh "$CHECKS/mode.sh" manual --review "$T/review" > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "the spec repository could not be read into ViD's copy .*run this again" "$T/mo" || fail "the switch with the spec repository's read failing exited $RC, not refused to run again"
grep -q 'the read the case makes fail' "$T/mo" || fail "the refusal does not give git's words"
grep -q '^need ' "$T/mo" && fail 'a failed read of the spec repository was asked of the owner'
grep -q '^taken-over ' "$T/mo" && fail 'a ticket was taken over after a failed read'
[ ! -s .vid/tw/applied ] || fail 'an applied version was recorded after a failed read'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the failed read of the spec repository'

# 2. the spec repository's main back, the export lines still gone and no local copy: the applied commit found from the newest
# export's message, read after a fetch of the spec repository; every input printed before the tickets are taken
# over; no --words, so it stops at the page
git --git-dir="$SR" update-ref refs/heads/main "$SM"
# the first export's pushed line back alone: the log names one candidate export and not the newest, so the exports are ordered by
# ancestry in the spec repository read into ViD's copy, never by the log alone
grep "^export $X1 .* state=pushed " "$T/xl" >> .vid/tw/log
RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'the page is written' "$T/mo" || fail "the switch run with the export only on the spec repository exited $RC, not stopped at the page"
grep -q '^need ' "$T/mo" && fail 'the switch asked for an input the spec repository holds'
grep -q '^found register .* — .*vid:ticket' "$T/mo" || fail 'the register found is not printed with where it came from'
grep -q "^found plan .* — .*\.vid/plans/$PH\.plan" "$T/mo" || fail "the plan found is not printed as .vid/plans/<the newest ticket's plan>.plan"
grep -q '^found plan-md .* — .*HEAD' "$T/mo" || fail "PLAN.md found is not printed as HEAD's"
grep -q "^found applied $H2 — .*$X2.*message" "$T/mo" || fail "the applied commit is not found from the newest export's message ($H2 of $X2), printed with where it came from"
f=$(grep -n '^found applied ' "$T/mo" | cut -d: -f1); t=$(grep -n '^taken-over ' "$T/mo" | head -n 1 | cut -d: -f1)
[ -n "$t" ] && [ "$f" -lt "$t" ] || fail 'the inputs are not printed before the tickets are taken over'
for k in 1 2 3; do eval "n=\$N$k"; grep -q "^taken-over $n " "$T/mo" && grep -q "^published $n .* taken-over=" .vid/tw/log || fail "#$n is not taken over"
  cmp -s ".vid/tw/out/issue-$n.md" "$T/t$k" || fail "#$n is not recorded at its newest writing"; done
grep -q "^not-taken-over $N5 " "$T/mo" || fail "#$N5, labelled but with no writing, is not listed as not taken over"
grep -q "^[a-z-]* $N4 " "$T/mo" && fail "#$N4, an issue with no ticket label, is listed"

# 3. the export lines back and no applied version recorded: the applied commit found from the newest export's log line
grep -v '^export ' .vid/tw/log > "$T/lg2" || :; cat "$T/lg2" "$T/xl" > .vid/tw/log; rm -f .vid/tw/applied
RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" --words 'yes, ratify the taken-over plan' > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the switch run with no input file exited $RC"
grep -q '^need ' "$T/mo" && fail 'the switch asked for an input its records or GitHub hold'
grep -q "^found applied $H2 — .*$X2.*\.vid/tw/log" "$T/mo" || fail "the applied commit found is not the newest export's H ($H2 of $X2) from the log, printed with where it came from"
[ "$(sed -n 1p .vid/tw/applied)" = "$H2" ] || fail "the applied version recorded is not the newest export's H"
grep -qx 'mode: GitHub manual, recorded' "$T/mo" || fail 'the switch did not say the mode is recorded'
git show HEAD:PLAN.md | cmp -s - PLAN.md && [ -z "$(git status --porcelain -- PLAN.md)" ] || fail "the PLAN.md used is not HEAD's text"
[ "$(sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS")" = manual ] || fail 'github-mode is not manual'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the switch'

# 3b. a re-take with no input flag: the recorded applied commit and RUN-STATE's plan used, each printed with where it is recorded
RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" --words 'yes, re-take' > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 0 ] && grep -qx 'mode: GitHub manual, re-taken' "$T/mo" || fail "the re-take with no input flag exited $RC, not re-taken"
grep -q '^need ' "$T/mo" && fail 'the re-take asked for an input its records hold'
grep -q "^found applied $H2 — .*\.vid/tw/applied" "$T/mo" || fail 'the re-take did not print the recorded applied commit, with where it is recorded'
grep -q "^found plan .* — RUN-STATE.md's plan" "$T/mo" || fail "the re-take did not print RUN-STATE's plan, with where it is recorded"
[ "$(sed -n 1p .vid/tw/applied)" = "$H2" ] || fail 'the re-take moved the applied version'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the re-take'

# 4. a list still at its limit when the cap is reached may be cut: --register alone is asked for, saying why
RC=0; VID_TICKETS_LIMIT=2 VID_TICKETS_CAP=4 sh "$CHECKS/mode.sh" manual --review "$T/review" --words 'yes, re-take' > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 5 ] && [ "$(grep -c '^need ' "$T/mo")" = 1 ] && grep -q '^need --register — .*may be cut' "$T/mo" || fail "a list past the cap exited $RC, not 5 asking for --register alone, saying it may be cut"
[ -z "$(mn_lock)" ] || fail 'the lock is held after the need for --register'

# every write since the fixture's clear, by the found runs and the refused alike, went to the state repository
# alone, never to the code or the spec repository (GM M2)
grep -v '^owner/vid-state ' "$FAKEGH/writes" > "$T/w" && { cat "$T/w" >&2; fail 'the switch wrote to a repository other than the state repository (the lines above)'; }
echo 'mode-find-inputs: ok'
