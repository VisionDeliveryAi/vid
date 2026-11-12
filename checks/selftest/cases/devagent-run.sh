#!/bin/sh
# Purpose: selftest case — DevAgent's reported run (v0.26.10.24.1 R4, R6, R7), on the fixture project with a local bare
# repository as origin. A run at a named commit pushes vid-results/<id>, one commit labelled Role: TM, whose tree holds
# only <id>/, with results.txt (by: TM first, the full commit, the engines, the environments, a stand-in: line) and one
# cases file per engine; a second report for the same ask gets attempt 2; a hung case is stopped at the case limit and
# reported failed by name, and the run goes on; a runner that writes no report once is run again, and twice pushes
# nothing and exits 2 with its last lines; with no product, a case that reaches for it errors with setup: and the report
# is still pushed; a commit not on origin is not pushed; nothing the run started is left running, a stray process
# stopped and named; the watcher stops a silent run and a dying service stops a run, both pushing nothing and the first
# saying the analyst is due; covers: lines reach results.txt one per row, the lowest, from the pass that wrote the report alone;
# a product logging to its stdout does not turn the silence stop off; a report cut off mid-write counts as none; start, wait and stop work a detached run; the setup and slow triggers fire; a missing record
# and a work folder under ViD's records run nothing. v0.26.10.24.2 R2: the builder's own run takes the clone as it stands, an
# uncommitted case included, in the primary engine, fetches and pushes nothing, writes no report and leaves nothing running; it
# needs the record's entry: line and a clone under the work folder. R4: red-<n> in the primary engine alone, with its rows:, one
# cases file, a second gets attempt 2; another engine or no rows: is not run. R5: engines: only in a run of every declared
# engine, the record's list in the record's order; the sort, for H11's items 2 and 7, below; an engine the record does not declare is not run. A red run with no product is not run. R6: no covers: line in a report whose run printed none. v0.26.10.24.7: J12's safety rules, the analyst and memory admission. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$CHECKS/../devagent/test-manager/run.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"
S=$T/work/dev-setup.txt; H=$(printf %s "$SP_C" | cut -c1-12)
run() { RC=0; sh "$R" run --setup "$S" --commit "$SP_C" "$@" > "$T/out" 2>&1 || RC=$?; }
O="git -C $T/origin.git"
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
show() { $O show "vid-results/$1"; }
alive() { kill -0 "$1" 2>/dev/null; }
# the report: alone on its branch, labelled, one cases file per engine
run --ask "pr-1-$H" --select 'ROW-00[12]' --line 'stand-in: mail — a fake — the real service'
[ "$RC" = 0 ] || fail "a good run exited $RC"
[ "$(tree "pr-1-$H-1")" = "pr-1-$H-1/cases-alpha.xml pr-1-$H-1/cases-beta.xml pr-1-$H-1/results.txt " ] || fail "the tree: $(tree "pr-1-$H-1")"
[ "$($O rev-list --count "vid-results/pr-1-$H-1")" = 1 ] || fail 'the report is not one commit of its own'
$O log -1 --format=%B "vid-results/pr-1-$H-1" | grep -qx 'Role: TM' || fail 'the report commit has no Role: TM'
F=vid-results/pr-1-$H-1:pr-1-$H-1
[ "$($O show "$F/results.txt" | head -n 1)" = 'by: TM' ] || fail 'results.txt does not begin by: TM'
for l in "commit: $SP_C" 'engines: alpha beta' 'environments: 1' 'stand-in: mail — a fake — the real service'; do
  $O show "$F/results.txt" | grep -qxF "$l" || fail "results.txt lacks: $l"; done
$O show "$F/cases-beta.xml" | grep -q 'name="ROW-002-product" time="[0-9]*"/>' || fail 'the product was not up for ROW-002'
grep -q '^cases: 4 passed, 0 failed' "$T/out" || fail 'the counts over two engines'
grep -qx 'leftovers: none' "$T/out" || fail 'a clean run did not say leftovers: none'
alive "$(cat "$T/product.was")" && fail 'the product is still running'
$O show "$F/results.txt" | grep -q '^covers:' && fail 'a covers: line from a run that printed none'
# attempt 2; R5: a run in fewer engines than the record declares has no engines: line, every one in any order has it
run --ask "pr-1-$H" --select ROW-001 --engines alpha; has "pr-1-$H-2" || fail 'no attempt 2'
$O show "vid-results/pr-1-$H-2:pr-1-$H-2/results.txt" | grep -q '^engines:' && fail 'a run in one engine of two declares engines:'
run --ask "pr-1-$H" --select ROW-001 --engines 'beta alpha'; $O show "vid-results/pr-1-$H-3:pr-1-$H-3/results.txt" | grep -qx 'engines: alpha beta' || fail "a run of every engine lacks the record's engines: line"
run --ask "pr-1-$H" --engines gamma; [ "$RC" = 1 ] && grep -q 'no engine gamma' "$T/out" || fail 'an engine the record does not declare ran'
# R4: the red run
run --ask red-7 --select 'ROW-00[12]' --line 'rows: ROW-001 ROW-002'; [ "$RC" = 0 ] || fail "a red run exited $RC"
[ "$(tree red-7-1)" = 'red-7-1/cases-alpha.xml red-7-1/results.txt ' ] || fail "the red tree: $(tree red-7-1)"
$O show vid-results/red-7-1:red-7-1/results.txt > red; grep -qx "commit: $SP_C" red && grep -qx 'rows: ROW-001 ROW-002' red || fail 'the red report lacks its commit or rows:'
grep -q '^engines:' red && fail 'a red run in one engine of two declares engines:'
run --ask red-7 --select ROW-001 --line 'rows: ROW-001'; has red-7-2 || fail 'no second red report'
run --ask red-8 --select ROW-001; [ "$RC" = 1 ] && grep -q 'rows: line' "$T/out" && ! has red-8-1 || fail 'a red run with no rows: line ran'
run --ask red-8 --engines beta --line 'rows: ROW-001'; [ "$RC" = 1 ] && grep -q 'primary engine, alpha' "$T/out" && ! has red-8-1 || fail 'a red run outside the primary engine ran'
run --ask red-8 --no-product --line 'rows: ROW-001'; [ "$RC" = 1 ] && grep -q 'has the product running' "$T/out" && ! has red-8-1 || fail 'a red run with no product ran'
# R2: the builder's own run, on a record whose repo: leads nowhere, so nothing can be fetched or pushed
git clone -q origin.git work/bu; printf 'exit 0\n' > work/bu/tests/cases/ROW-009-new.sh; (cd work/bu && git add tests)
own() { RC=0; sh "$R" run --setup "$1" --here "$2" --select "$3" > "$T/out" 2>&1 || RC=$?; }
own "$S" work/bu ROW-009; [ "$RC" = 1 ] && grep -q 'no entry:' "$T/out" || fail 'an own run with no entry: in the record'
sed 's|^repo: .*|repo: /nowhere|' "$S" > work/e.txt; echo 'entry: the product line of start:' >> work/e.txt; REFS=$($O for-each-ref | wc -l)
own work/e.txt dev ROW-009; [ "$RC" = 1 ] && grep -q 'not under the work folder' "$T/out" || fail 'an own run outside the work folder'
RC=0; sh "$R" run --setup work/e.txt --here work/bu --ask x > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'an own run took --ask'
own work/e.txt work/bu 'ROW-00[29]'; [ "$RC" = 0 ] || fail "an own run exited $RC"
grep -q '^cases: 2 passed, 0 failed' "$T/out" || fail 'the own run: the uncommitted case, or the product, was not there'
X=$(sed -n 's/.*nothing pushed: //p' "$T/out"); [ "$(basename "$X")" = cases-alpha.xml ] && grep -q 'name="ROW-009-new"' "$X" || fail 'the own run does not name its cases file'
[ "$(ls "$(dirname "$X")" | grep -c '^cases-')" = 1 ] && [ ! -e "$(dirname "$X")/report" ] || fail 'the own run wrote a report'
[ "$($O for-each-ref | wc -l)" = "$REFS" ] || fail 'the own run pushed'
[ -f work/bu/tests/cases/ROW-009-new.sh ] && [ -n "$(git -C work/bu status --porcelain)" ] || fail 'the own run changed the clone'
grep -qx 'leftovers: none' "$T/out" && ! alive "$(cat "$T/product.was")" || fail 'the own run left something running'
D=$(sh "$R" start --setup work/e.txt --here work/bu --select ROW-009); RC=0; sh "$R" wait "$D" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && grep -q '^cases: 1 passed' "$T/out" || fail "a detached own run: wait exited $RC"
# the case limit: stopped, failed by name, and the run goes on
run --ask "pr-2-$H" --select 'ROW-00[34]' --engines alpha; [ "$RC" = 0 ] || fail "the hung case's run exited $RC"
X=$($O show "vid-results/pr-2-$H-1:pr-2-$H-1/cases-alpha.xml")
printf %s "$X" | grep -q 'name="ROW-003-hangs".*<failure' || fail 'the hung case is not failed by name'
printf %s "$X" | grep -q 'name="ROW-004-after" time="[0-9]*"/>' || fail 'the run did not go on after the hung case'
grep -q '^broken: 1 stopped at the case limit' "$T/out" || fail 'the broken case is not sorted by its message'
# no results report: once, run again; twice, nothing pushed, and the last lines
run --ask "pr-3-$H" --select noreport-once --engines alpha; has "pr-3-$H-1" || fail 'a run that wrote no report was not run once more'
run --ask "pr-4-$H" --select noreport --engines alpha
[ "$RC" = 2 ] || fail "no report twice exited $RC"; has "pr-4-$H-1" && fail 'no report twice pushed'
grep -q 'nothing collected' "$T/out" || fail 'no last lines'
[ "$(grep -c '^== alpha, pass' "$T/out")" = 2 ] || fail 'not two passes'
# no product: an error, setup:, and the report still pushed
run --ask "pr-5-$H" --no-product --select ROW-002 --engines alpha; has "pr-5-$H-1" || fail 'no product pushed nothing'
$O show "vid-results/pr-5-$H-1:pr-5-$H-1/cases-alpha.xml" | grep -q 'message="setup: no product' || fail 'no setup: message'
grep -q '1 errored' "$T/out" || fail 'a setup: failure is not an error'
# R12 (v0.26.10.25.3): a pull request's head runs' setup: errors add up across its runs, whatever their time: at 5 the analyst is due, once; another pull request counts its own
for i in 1 2 3 4; do run --ask "pr-30-$H" --no-product --select ROW-002; grep '^analyst due: setup' "$T/out" > "due$i" || true; done
[ ! -s due1 ] && [ ! -s due2 ] && [ "$(cat due3)" = 'analyst due: setup errors=6 runs=3' ] && [ ! -s due4 ] || fail "the setup count across runs: $(cat due1 due2 due3 due4)"
run --ask "pr-31-$H" --no-product --select ROW-002; ! grep -q '^analyst due: setup' "$T/out" || fail 'another pull request took the count'
# R8 (v0.26.10.25.3): a close chunk's run, req-<issue>-<chunk>: its next attempt, by: TM, the asked commit, a cases file for each engine given, and no line of a head or red run; a malformed ask is not run
run --ask req-9-p2c1 --select 'ROW-00[12]' --engines beta; [ "$RC" = 0 ] || fail "a close chunk's run exited $RC"
[ "$(tree req-9-p2c1-1)" = 'req-9-p2c1-1/cases-beta.xml req-9-p2c1-1/results.txt ' ] || fail "the close chunk's tree: $(tree req-9-p2c1-1)"
$O show vid-results/req-9-p2c1-1:req-9-p2c1-1/results.txt > rq; [ "$(head -n 1 rq)" = 'by: TM' ] && grep -qx "commit: $SP_C" rq && ! grep -qE '^(stand-in|retested|rows):' rq || fail "the close chunk's results.txt: $(cat rq)"
run --ask req-9-p2c1 --select ROW-001 --engines 'alpha beta'; [ "$(tree req-9-p2c1-2)" = 'req-9-p2c1-2/cases-alpha.xml req-9-p2c1-2/cases-beta.xml req-9-p2c1-2/results.txt ' ] || fail "the chunk's second attempt: $(tree req-9-p2c1-2)"
run --ask req-9-p2c10 --select ROW-001 --engines beta; has req-9-p2c10-1 || fail 'p2c10 took p2c1 as its own'
run --ask req-9-p2c1 --select ROW-001 --engines beta --line 'stand-in: mail — a fake — the real service'; [ "$RC" = 1 ] && grep -q 'no retested:, stand-in: or rows: line' "$T/out" && ! has req-9-p2c1-3 || fail 'a close run carried a line'
run --ask req-9-chunk --engines beta; [ "$RC" = 1 ] && grep -q "not a close chunk's ask" "$T/out" && ! has req-9-chunk-1 || fail 'a malformed close ask ran'
# a commit not on origin
( cd dev && sp_git commit -q --allow-empty -m 'local only' ); L=$(git -C dev rev-parse HEAD); RC=0
sh "$R" run --setup "$S" --commit "$L" --ask local > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] || fail "a commit not on origin exited $RC"; has local-1 && fail 'a commit not on origin was pushed'
# a stray process: stopped, by its group, and named
run --ask "pr-6-$H" --select stray --engines alpha; alive "$(cat "$T/stray")" && fail 'the stray process lives'
grep -q '^leftovers: stopped group' "$T/out" || fail 'the stray process is not named'
# the watcher, and a dying service: nothing pushed
cp "$S" work/w.txt; printf 'silent-seconds: 2\nservices: cat "$SP_T/dead" 2>/dev/null\nservice-seconds: 1\n' >> work/w.txt; S=$T/work/w.txt
run --ask "pr-7-$H" --select quiet --engines alpha; [ "$RC" = 3 ] || fail "a silent run exited $RC"; has "pr-7-$H-1" && fail 'a silent run pushed'
grep -q '^analyst due: cap stop=silent last-output=' "$T/out" || fail 'the cap trigger did not fire'
run --ask "pr-8-$H" --select dies --engines alpha; [ "$RC" = 3 ] || fail "a dead service's run exited $RC"
grep -q '^stopped: service dead' "$T/out" || fail 'the dying service is not named'
# a product logging to its stdout is not the tests' output: silence still stops the run
sed 's|^start: .*|start: { while :; do echo product-line; sleep 1; done; } \&|' work/w.txt > work/n.txt; S=$T/work/n.txt
run --ask "pr-11-$H" --select quiet --engines alpha; [ "$RC" = 3 ] || fail "a chatty product's silent run exited $RC, not 3"; S=$T/work/dev-setup.txt
# covers: from the log of the pass that wrote the report, a case's own included, one per row, the lowest; a first pass's left out
{ grep -v '^run:' "$S"; cat <<'E'
run: [ -f "$SP_T/c1" ] || { : > "$SP_T/c1"; echo 'covers: ROW-008 1'; exit 4; }; printf 'covers: ROW-002 2\ncovers: ROW-001 9\ncovers: ROW-001 9\n'; SP_COVER=1 sh tests/runner.sh
E
} > work/c.txt; S=$T/work/c.txt; run --ask "pr-12-$H" --select ROW-001 --engines alpha; S=$T/work/dev-setup.txt; has "pr-12-$H-1" || fail "the covers run exited $RC"
[ "$($O show "vid-results/pr-12-$H-1:pr-12-$H-1/results.txt" | grep '^covers:' | tr '\n' ';')" = 'covers: ROW-001 3;covers: ROW-002 2;' ] || fail 'the covers: lines of the report'
# a runner killed mid-write: a report cut short is none, and nothing is pushed
sed 's|^run: .*|run: printf "<testsuite name=\\"toy\\"><testcase name=\\"ROW-001\\"" > "$RESULTS"; exit 137|' "$S" > work/k.txt; S=$T/work/k.txt
run --ask "pr-13-$H" --engines alpha; S=$T/work/dev-setup.txt; [ "$RC" = 2 ] || fail "a report cut short exited $RC, not 2"; has "pr-13-$H-1" && fail 'a report cut short was pushed'
# detached: start, wait, stop
D=$(sh "$R" start --setup "$S" --commit "$SP_C" --ask "pr-9-$H" --select ROW-001 --engines alpha)
RC=0; sh "$R" wait "$D" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && has "pr-9-$H-1" || fail "a detached run: wait exited $RC"
D=$(sh "$R" start --setup "$S" --commit "$SP_C" --ask "pr-10-$H" --select quiet --engines alpha); i=0
until grep -q '^runner:' "$D/log" 2>/dev/null || [ "$i" -ge 30 ]; do sleep 1; i=$((i + 1)); done; sh "$R" stop "$D"
RC=0; sh "$R" wait "$D" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] || fail "a stopped run: wait exited $RC"; has "pr-10-$H-1" && fail 'a stopped run pushed'
# the setup and slow triggers, read from a report's times, a runner's classname before each name
{ echo '<testsuite name="toy">'; for i in 1 2 3 4 5; do printf '<testcase classname="c" name="ROW-%s" time="61">\n<failure message="no mail">x</failure>\n</testcase>\n' "$i"; done
  echo '<testcase classname="c" name="ROW-6" time="300"/></testsuite>'; } > slow.xml
sed 's|^run: .*|run: cp "$SP_T/slow.xml" "$RESULTS"|' "$S" > work/s.txt; S=$T/work/s.txt; run --ask slow --engines alpha; S=$T/work/dev-setup.txt
for l in 'analyst due: setup cases=5' 'analyst due: slow cases=ROW-6' 'broken: 5 no mail' 'cases: 1 passed, 5 failed, 0 errored, 0 skipped'; do
  grep -qxF "$l" "$T/out" || fail "the sort lacks: $l"; done
# v0.26.10.24.7 (J12): broken: names its cases; a slow case already asked about fires no more; no fault run asks for the analyst
grep -qxF 'broken cases: ROW-1, ROW-2, ROW-3, ROW-4, ROW-5 — no mail' "$T/out" || fail 'broken: names no cases'; S=$T/work/s.txt; run --ask slow --engines alpha; grep -q '^analyst due: slow' "$T/out" && fail 'a slow case fired twice'; grep -qxF 'analyst due: setup cases=5' "$T/out" || fail 'the setup trigger went with it'
(cd dev && echo bad > product.txt && git diff > "$T/work/p.patch" && git checkout -q product.txt); printf 'ROW-6\tp.patch\tnone\tx\n' > work/list; run --ask "pr-20-$H" --engines alpha; run --ask "pr-20-$H" --faults "$T/work/list"; [ "$RC" = 0 ] || fail "the fault run exited $RC"; grep -q '^analyst due' "$T/out" && fail 'a fault run asked for the analyst'; S=$T/work/dev-setup.txt
# J12: a log past its cap keeps its end; a failed stop: keeps the environment and stops later runs; stop acts on the recorded start alone; memory admission
sed -e 's|^run: .*|run: i=0; while [ $i -lt 400 ]; do echo line$i; i=$((i + 1)); done; sleep 3; cp "$SP_T/slow.xml" "$RESULTS"|' -e '$a\
log-bytes: 500' "$S" > work/l.txt; S=$T/work/l.txt; run --ask cap --engines alpha; S=$T/work/dev-setup.txt; L=$(ls -td work/runs/*/ | head -n 1)log; [ "$(wc -c < "$L")" -le 2000 ] && grep -qx line399 "$L" || fail "the log's cap: $(wc -c < "$L")"
sed 's|^stop: .*|stop: exit 7|' "$S" > work/f.txt; S=$T/work/f.txt; run --ask sf --engines alpha --select ROW-001; [ "$RC" = 3 ] && [ -f work/stop-failed ] && has sf-1 && fail 'a failed stop pushed'; [ "$RC" = 3 ] && grep -q 'stop: failed, exit 7' "$T/out" && alive "$(cat "$T/product.pid")" || fail 'a failed stop: did not keep the environment'; run --ask sf --engines alpha --select ROW-001; [ "$RC" = 1 ] && grep -q 'stop: failed' "$T/out" || fail 'a later run went'; S=$T/work/dev-setup.txt; kill "$(cat "$T/product.pid")"; rm -f work/stop-failed "$T/product.pid"
D=$(sh "$R" start --setup "$S" --commit "$SP_C" --ask "pr-11-$H" --select quiet --engines alpha); i=0; until [ -f "$D/lstart" ] || [ "$i" -ge 20 ]; do sleep 1; i=$((i + 1)); done; cp "$D/lstart" lst; echo x > "$D/lstart"; RC=0; sh "$R" stop "$D" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'not its start' "$T/out" || fail 'stop signalled another start'; cp lst "$D/lstart"; sh "$R" stop "$D"; sh "$R" wait "$D" > /dev/null 2>&1 || true
sleep 300 & Z=$!; mkdir -p work/runs/other; echo $Z > work/runs/other/pid; sh "$R" stamp $Z > work/runs/other/lstart; : > work/runs/other/admitted; sed -e '$a\
measured: 4 100 2026-01-01T00:00:00Z' -e '$a\
free-memory: [ -f "$SP_T/room" ] && echo 9000 || echo 10' "$S" > work/m.txt; D=$(sh "$R" start --setup "$T/work/m.txt" --commit "$SP_C" --ask "pr-12-$H" --select ROW-001 --engines alpha); i=0; until grep -q 'waiting for memory' "$D/log" 2>/dev/null || [ "$i" -ge 20 ]; do sleep 1; i=$((i + 1)); done; grep -qx 'waiting for memory' "$D/log" && [ ! -f "$D/exit" ] || fail 'no wait for memory'; : > room; until [ -f "$D/exit" ] || [ "$i" -ge 40 ]; do sleep 1; i=$((i + 1)); done; kill "$Z"; rm -rf work/runs/other; has "pr-12-$H-1" || fail 'the run did not go on once there was room'
# v0.26.10.24.4: two failures differing by an address are one broken: group; system-out, a testsuites wrapper and an escaped line break read as the format says
{ printf '<testsuites><testsuite name="toy"><testcase name="ROW-1" time="1"><system-out>said\nerror reading a setting\nskipped 2 steps</system-out><system-err>e</system-err></testcase>\n'
  printf '<testcase name="ROW-%s"><failure message="ROW-%s: no item at 0x%s&#10;trace">x\nerror in the traceback</failure></testcase>\n' 2 2 7f00aa11 3 2 7F00BB22; echo '</testsuite></testsuites>'; } > addr.xml
sed 's|^run: .*|run: cp "$SP_T/addr.xml" "$RESULTS"|' "$S" > work/a.txt; S=$T/work/a.txt; run --ask addr --engines alpha; S=$T/work/dev-setup.txt
for l in 'cases: 1 passed, 2 failed, 0 errored, 0 skipped' 'broken: 2 ROW-2: no item at 0x'; do grep -qxF "$l" "$T/out" || fail "the sort lacks: $l"; done
# the selection's form: bare names go into the record's select-form:, in a run and in a fault line; runner words and a path stand; a record with none takes them as given
last() { sed -n 's/^== [a-z]*, pass 1, selection \(.*\), at .*/\1/p' "$(ls -td work/runs/*/ | head -n 1)log" | tail -n 1; }
S0=$S; { cat "$S"; echo 'select-form: ROW-00<words>'; } > work/f.txt; S=$T/work/f.txt
run --ask form-1 --select 1 --engines alpha; [ "$(last)" = ROW-001 ] || fail "the record's form was not taken: $(last)"
run --ask form-2 --select '-x 1' --engines alpha; [ "$(last)" = '-x 1' ] || fail "runner words were changed: $(last)"
run --ask form-3 --select tests/cases --engines alpha; [ "$(last)" = tests/cases ] || fail "a path was changed: $(last)"
S=$S0; run --ask form-4 --select ROW-001 --engines alpha; [ "$(last)" = ROW-001 ] || fail "no form in the record, and the words changed: $(last)"
# R9: a remote that refuses once: the report's push is tried again
printf '#!/bin/sh\n[ -f "%s/once" ] && exit 0; : > "%s/once"; exit 1\n' "$T" "$T" > origin.git/hooks/pre-receive; chmod +x origin.git/hooks/pre-receive; run --ask retry-1 --select ROW-001 --engines alpha; rm -f origin.git/hooks/pre-receive; [ "$RC" = 0 ] && has retry-1-1 || fail 'a push refused once lost its report'
# run nothing: no record; a work folder under ViD's records
RC=0; sh "$R" run --setup "$T/none" --commit "$SP_C" --ask x > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'ran with no record'
mkdir -p v/.vid v/w; cp "$S" v/w/; RC=0; sh "$R" run --setup "$T/v/w/dev-setup.txt" --commit "$SP_C" --ask x > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && has x-1 && fail 'ran under a folder of records'; grep -q "folder of ViD's records" "$T/out" || fail 'ran under a folder of records'
exit 0
