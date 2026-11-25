#!/bin/sh
# Purpose: selftest case — a known limit is named in each stage's summary and report (FB-7 A3), checks/close.sh on the writer's toy and the
# fake gh. The facts hold one line for each row of the stages up to N the owner ruled a limit (an earlier stage's too, a journey by its
# row, or by the transitions ruled when not all are), with its requirement's name, its promise, who and when, with the words only its own ruling holds, and its result at the full run and at the
# staging run (passed, failed, could not run, not run); none for a row out of them or whose ruling a landing reset. The close is refused for a summary with no line for one, two rows of one name two
# lines; the report carries the facts' lines. Env: CHECKS.
set -eu
HOME=$(mktemp -d); export HOME; unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T" "$HOME"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "limit-in-summary: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cl_toy; F=$K
for r in ROW-003 ROW-006 ROW-001 DIF-001; do limit $r; done; printf 'ROW-004-T1\tknown limit\tx\nROW-004-T2\taccepted\tx\nROW-017\tknown limit\tx\n' >> .vid/decide/state
printf '2026-11-10T10:00:00Z\tROW-003\tlimit\tthe lab has no printer\towner\n2026-11-10T11:00:00Z\tROW-006\tlimit\t\towner\n2026-11-10T12:00:05Z\tROW-001\tlimit\t\tdelegate\n' >> .vid/decide/rulings
mkdir -p .vid/decide/queue; printf '2026-11-10T11:00:01Z\theld:ROW-006\tc\tnot on this phone\towner\truled\n2026-11-10T12:00:09Z\tclose:stage-1/1:red:p2c1\tlimit\tanother row'"'"'s words\tdelegate\truled\n' >> .vid/decide/queue/answers
mkdir -p $K/d1 $K/cs $K/w1; : > $K/passed; : > $K/done; : > $K/d1/passed; : > $K/cs/passed; : > $K/cs/ask; : > $K/w1/done
printf 'chunk\tp1c1\tgreen\t1\nrow\tp1c1\talpha\tROW-003\tpassed\nrow\tp2c1\tbeta\tROW-003\tfailed\tx\nrow\tp1c1\talpha\tROW-006\tcould not run\nrow\tp1c1\talpha\tROW-001\tpassed\n' > $K/read; printf 'chunk\tp1c1\tgreen\t1\nrow\tp1c1\talpha\tROW-003\tpassed\nrow\tp1c1\talpha\tDIF-001\tfailed\tx\n' > $K/cs/read
cs summary --stage 1; grep '^limit' $K/facts.txt | cut -f2 | sort | paste -sd ' ' - > "$T/l"; [ "$(cat "$T/l")" = 'DIF-001 ROW-001 ROW-003 ROW-004-T1 ROW-006' ] || fail "the limits named: $(cat "$T/l")"
l() { grep "^limit${TAB}$1${TAB}" $K/facts.txt; }
l ROW-003 | grep -q "${TAB}owner, 2026-11-10T10:00:00Z: the lab has no printer${TAB}full run: failed · staging run: passed\$" || fail "ROW-003's fact: $(l ROW-003)"
l ROW-006 | grep -q "${TAB}owner, 2026-11-10T11:00:00Z${TAB}full run: could not run · staging run: not run\$" || fail "ROW-006's fact: $(l ROW-006)"
l ROW-001 | grep -q "${TAB}delegate, 2026-11-10T12:00:05Z${TAB}full run: passed · staging run: not run\$" || fail "ROW-001's fact: $(l ROW-001)"
l DIF-001 | grep -q "${TAB}the owner${TAB}full run: not run · staging run: failed\$" || fail "DIF-001's fact: $(l DIF-001)"; l ROW-006 | grep -q 'Every page shows the header' || fail "the promise: $(l ROW-006)"
# a run with no read: not run, one line each
mv $K/cs/read "$T/csr"; cs summary --stage 1; [ "$(grep -c '^limit' $K/facts.txt)" = 5 ] && [ "$(grep -c 'staging run: not run$' $K/facts.txt)" = 5 ] || fail "the facts with no staging run's read: $(grep '^limit' $K/facts.txt)"; mv "$T/csr" $K/cs/read
# a landing that reset it: no longer in force
cp .vid/decide/state "$T/st"; grep -v '^ROW-001	' "$T/st" > .vid/decide/state; cs summary --stage 1; ! l ROW-001 || fail 'a limit a landing reset is named'; cat "$T/st" > .vid/decide/state
# the close: refused for a summary that misses a line; two rows of one name need two
sh "$CHECKS/plan.sh" parse 2>/dev/null | awk -F'\t' '$1 == "row" && $3 ~ /^S0[234]$/ { print $2 }' | while read -r r; do state "$r" paid; done; for r in ROW-006 ROW-001 DIF-001; do state $r known-limit; done
for q in $(sed -n 's/^reqs\t//p' $K/s1ask); do printf '%s\tpass\t1\n' "$q"; done > .vid/decide/stage/1/s1; : > $K/s1done; : > $K/findings; fetch; cs conds 1; [ ! -s "$T/out" ] || fail 'the stage has a condition unmet'
nm() { l "$1" | cut -f3; }; sumr() { { printf 'Went back: '; awk -F'\t' '$1 == "went-back" { printf "%s; ", $3 }' $K/facts.txt; printf '\nDecided for you: '; awk -F'\t' '$1 == "decided" { printf "%s; ", $2 }' $K/facts.txt; printf '\n\n## Known limits\n\n'; for x in "$@"; do printf -- '- %s: still short of its promise.\n' "$(nm $x)"; done; printf '\n## Next\n\n%s\n' "$(nm ROW-003)"; } > $K/summary.md; }
sumr ROW-001 ROW-003 DIF-001 ROW-004-T1; cs close-stage --stage 1; ok "^summary-refused 1 the summary's known limits miss: "
sumr ROW-001 ROW-003 DIF-001 ROW-004-T1 ROW-006; cs close-stage --stage 1; ok '^stage-closed 1 at '
awk '/^## Known limits/ { f = 1; next } /^## / { f = 0 } f' $K/report.md > "$T/kl"; [ "$(grep -c '^- ' "$T/kl")" = 5 ] && grep -q '^- ROW-003: .* — owner, 2026-11-10T10:00:00Z: the lab has no printer — full run: failed · staging run: passed$' "$T/kl" || fail "the report's known limits: $(cat "$T/kl")"
exit 0
