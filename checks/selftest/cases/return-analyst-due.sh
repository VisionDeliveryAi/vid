#!/bin/sh
# Purpose: selftest case — "analyst due" reaches the run manager (v0.9.7.0.9
# spec 3.4, R4). `sh checks/test.sh analyst-due` prints `analyst due:
# request=<t> reason=<r>` for each `analyst-due` event at the run's home
# with no `analyst-done request=<t>`, in order, at most 10 lines then
# `(+k more)`, from a worktree with no .vid/ as from the home; it writes
# nothing. `sh checks/brief.sh return` prints the same lines after its
# `ok` (v0.9.7.3: those of its own attempt's tickets — case
# return-analyst-due-try). With none open it prints nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "return-analyst-due: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/the repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
cp "$CHECKS/test.sh" "$CHECKS/plan.sh" checks/; g add -A && g commit -qm 'the test manager'
# v0.9.7.1 (3.9): a pass's receipt must have tested the committed protected paths — the toy's GREEN is re-pointed at this tree
sed -i.bak "s/^tree=.*/tree=$(git rev-parse 'HEAD^{tree}')/" .vid/ledger-results/$GREEN.tree && rm -f .vid/ledger-results/$GREEN.tree.bak
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: worktree-agent-a1\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | its case needs the preview route\n' "$(git rev-parse HEAD)" "$GREEN" > .vid/briefs/1/builder-1.return.md
# none open: nothing printed
sh checks/test.sh analyst-due > "$T/out" 2>&1 || fail 'the listing failed with no events'
[ ! -s "$T/out" ] || fail 'the listing printed something with no analyst-due'
E=.vid/metrics-events
printf 'analyst-due request=T1 reason=cap at=2026-10-06T01:00:00Z\n' >> $E
printf 'analyst-due request=T2 reason=setup group="db not ready" at=2026-10-06T01:01:00Z\n' >> $E
printf 'analyst-due request=T2 reason=slow rows=ROW-101 at=2026-10-06T01:01:00Z\n' >> $E
printf 'analyst-due request=T3 reason=slow cases=c1 at=2026-10-06T01:02:00Z\n' >> $E
printf 'analyst-done request=T3 reason=slow outcome=none at=2026-10-06T01:03:00Z\n' >> $E
printf 'analyst-done request=T1 reason=cap outcome=hang at=2026-10-06T01:04:00Z\n' >> $E
printf 'analyst-due request=T4 reason=cap at=2026-10-06T01:05:00Z\n' >> $E
N0=$(wc -l < $E)
sh checks/test.sh analyst-due > "$T/out" 2>&1 || fail 'the listing failed'
printf 'analyst due: request=T2 reason=setup\nanalyst due: request=T2 reason=slow\nanalyst due: request=T4 reason=cap\n' > "$T/want"
cmp -s "$T/out" "$T/want" || fail "the listing is not the three open dues: $(cat "$T/out")"
[ "$(wc -l < $E)" -eq "$N0" ] || fail 'the listing wrote to the events'
# brief.sh return: the same lines, after its ok — v0.9.7.3 (R9): only its own attempt's tickets', so T2 and T4 are
# tickets of the brief's try
for t in T2 T4; do mkdir -p ".vid/requests/$t"; printf 'type=iterate\nrole=builder\ntry=1-builder-1\n' > ".vid/requests/$t/request"; done
sh checks/brief.sh return .vid/briefs/1/builder-1.return.md > "$T/ret" 2>&1 || { cat "$T/ret" > "$T/out"; fail 'the hand-back was refused'; }
sed -n 1p "$T/ret" | grep -q '^ViD return: ok' || { cat "$T/ret" > "$T/out"; fail 'the first line is not the ok'; }
sed -n 2,4p "$T/ret" > "$T/got"; cmp -s "$T/got" "$T/want" || { cat "$T/ret" > "$T/out"; fail 'brief.sh return does not print the open dues after its ok'; }
# more than 10: ten lines, then (+k more)
k=5; while [ $k -le 14 ]; do printf 'analyst-due request=T%s reason=cap at=2026-10-06T02:00:00Z\n' "$k" >> $E; k=$((k + 1)); done
sh checks/test.sh analyst-due > "$T/out" 2>&1
[ "$(grep -c '^analyst due: ' "$T/out")" -eq 10 ] && [ "$(sed -n 11p "$T/out")" = '(+3 more)' ] && [ "$(grep -c . "$T/out")" -eq 11 ] || fail 'more than 10 open dues are not cut to 10 and (+k more)'
# from a worktree with no .vid/, inside the run: the home's dues
printf 'run: active\nsession: S1\nplan: required\nquestions: - · next Q1\nslice: 1 open    since: x    commit: x\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=12 at=2026-10-06T00:00:00Z\n' >> $E
g worktree add -q "$T/wt" -b wt
( cd "$T/wt" && sh checks/test.sh analyst-due ) > "$T/out" 2>&1
[ "$(sed -n 1p "$T/out")" = 'analyst due: request=T2 reason=setup' ] || fail "the listing from a worktree did not read the home: $(cat "$T/out")"
exit 0
