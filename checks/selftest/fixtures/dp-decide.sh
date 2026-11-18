# Purpose: selftest fixture — a head ViD accepts on its runs, for the Decisions section of a pull request's description
# (0.26.10.29.5, DP-1 R8). Sourced by the dp-r8-* cases once $T is made (Env: CHECKS, T). The results reader's toy
# (fixtures/results-reports.sh: rr_project, ticket 3), ticket mode's settings, the fake gh (fixtures/tickets.sh) with pull request 4
# open and its labels read, and the reports at head $RR_H of pull request 4 that the decider accepts every row on: T2, the head report
# with each needed fault, the grade and the sort (as decide-rows makes them). Helpers: dpd_body <text>: pull request 4's
# description; dpd_dc [--post]: `results.sh read` then `decide.sh decide --ticket 3 --pr 4 --head $RR_H`, the decision in $T/out,
# the exit in RC; dpd_rows: the rows' lines of the decision, its first two lines left out.
. "$CHECKS/selftest/fixtures/tickets.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
rr_project; : > .vid/RUN-STATE.md; printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
git init -q --bare "$T/code.git"; gh_fake; mv "$T/bin/gh" "$T/bin/gh-fake"
printf '#!/bin/sh\ncase "$1 $2 ${7:-}" in '"'"'pr view labels'"'"') cat "$FAKEGH/prs/$3/labels" 2>/dev/null | paste -sd , -; exit 0 ;; esac\nexec "$(dirname "$0")/gh-fake" "$@"\n' > "$T/bin/gh"; chmod +x "$T/bin/gh"
for n in 1 2 3 5; do mkdir -p "$T/gh/issues/$n/comments"; echo OPEN > "$T/gh/issues/$n/state"; done; mkdir -p "$T/gh/prs/4/comments"; echo OPEN > "$T/gh/prs/4/state"
rr_good; DPD_A=pr-4-$RR_H12-2; mkdir -p "$T/r/$DPD_A/faults"; cp "$T/r/pr-4-$RR_H12-1/results.txt" "$T/r/pr-4-$RR_H12-1/cases-alpha.xml" "$T/r/$DPD_A/"
dpd_fa() { rr_put "$DPD_A" "faults/$1/control.txt" ROW-001; rr_put "$DPD_A" "faults/$1/cases-alpha.xml" "$(rr_cases "$1=$2" ROW-001=pass)"; }
dpd_fa ROW-002-T1 fail:no; dpd_fa HOS-001 'fail:two&#10;vid-forbidden-effect: HOS-001'; rr_send "$DPD_A"
dpd_body() { printf '%s\n' "$1" > "$T/gh/prs/4/body"; }
dpd_dc() { sh "$CHECKS/results.sh" read --ticket 3 --pr 4 --head "$RR_H" > /dev/null 2>&1; RC=0; sh "$CHECKS/decide.sh" decide --ticket 3 --pr 4 --head "$RR_H" ${1:-} > "$T/out" 2>&1 || RC=$?; }
dpd_rows() { sed '1,2d' "$T/out" | grep -v '^decisions missing'; }
