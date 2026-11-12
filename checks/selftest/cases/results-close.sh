#!/bin/sh
# Purpose: selftest case — reading a step close (v0.26.10.25.3 R9). On made-up chunk reports req-<issue>-<chunk>-<k> at the asked commit:
# no report, absent; passed, failed, could not run; a journey's transition with no case, failed; a row with no case, failed in phase 1 and in
# phase 2 an engine line that stops nothing; could not run after an earlier attempt passed at the same commit, passed, and not after one at
# another; a case the row's newest accepted head report named that the close lacks, not run, that head the newest that is an ancestor of the
# close's commit; a refused report, absent with its refused line; a row failing in one engine and passing in another, a split line; chunk
# green, red, incomplete, absent; each failed row with its first failing case (v0.26.10.25.4 R1); the newest ask of the step's numbered asks
# (R3); the read file the same as what is printed; exit 0 throughout. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "results-close: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
R=$CHECKS/results.sh; rr_project; TAB=$(printf '\t'); C=$RR_H2; I=30
mkdir -p .vid/decide/close/S01; { printf 'issue\t%s\ncommit\t%s\n' "$I" "$C"; printf 'chunk\tp1c1\talpha\tROW-001 ROW-002\nchunk\tp1c2\talpha\tHOS-001 RULE-001\nchunk\tp1c3\talpha\tROW-009\n'
  printf 'chunk\tp2c1\tbeta\tROW-001 ROW-002\nchunk\tp2c2\tbeta\tHOS-001 RULE-001\n'; } > .vid/decide/close/S01/ask
rd() { RC=0; sh "$R" close --step S01 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "close exited $RC"; cmp -s "$T/out" .vid/decide/close/S01/read || fail 'the read file is not what was printed'; }
ln() { l=$(printf '%s\t' "$@"); l=${l%"$TAB"}; grep -qxF "$l" "$T/out" || fail "no line: $*"; }
no() { l=$(printf '%s\t' "$@"); l=${l%"$TAB"}; ! grep -qF "$l" "$T/out" || fail "a line: $*"; }
# cr <chunk> <k> <engine> <commit> <case…>: a chunk's report, sent
cr() { c=$1; k=$2; e=$3; m=$4; shift 4; i=req-$I-$c-$k; rm -rf "$T/r/$i"; rr_put "$i" results.txt "$(printf 'by: TM\ncommit: %s' "$m")"; rr_put "$i" "cases-$e.xml" "$(rr_cases "$@")"; rr_send "$i"; }
# nothing sent: every chunk absent, its rows not run
rd; ln chunk p1c1 absent -; ln chunk p2c2 absent -; ln row p1c1 alpha ROW-002 'not run'; ln row p2c2 beta RULE-001 'not run'; grep -q '^refused' "$T/out" && fail 'a refused line with no report'
# phase 1: passed; a journey by its transitions; a row with no case failed; setup: alone could not run
cr p1c1 1 alpha "$C" ROW-001-a=pass ROW-002-T1=pass ROW-002-T2=pass; cr p1c2 1 alpha "$C" HOS-001=err:setup:\ no\ door RULE-001=pass; cr p1c3 1 alpha "$C" ROW-008=pass; rd
ln chunk p1c1 green 1; ln row p1c1 alpha ROW-001 passed; ln row p1c1 alpha ROW-002 passed; ln chunk p1c2 incomplete 1; ln row p1c2 alpha HOS-001 'could not run'; ln row p1c2 alpha RULE-001 passed; ln chunk p1c3 red 1; ln row p1c3 alpha ROW-009 failed 'ROW-009 with no case'
cr p1c1 2 alpha "$C" ROW-001-a=pass ROW-002-T1=pass; rd; ln chunk p1c1 red 2; ln row p1c1 alpha ROW-002 failed 'ROW-002-T2 with no case'
# could not run, after an earlier attempt at another commit, stays; after one that passed at the same commit, passed
cr p1c2 1 alpha "$RR_H" HOS-001=pass RULE-001=pass; cr p1c2 2 alpha "$C" HOS-001=err:setup:\ no\ door RULE-001=pass; rd; ln row p1c2 alpha HOS-001 'could not run'
cr p1c2 1 alpha "$C" HOS-001=pass RULE-001=pass; rd; ln chunk p1c2 green 2; ln row p1c2 alpha HOS-001 passed
cr p1c2 3 alpha "$C" HOS-001=fail:broke RULE-001=pass; rd; ln chunk p1c2 red 3; ln row p1c2 alpha HOS-001 failed HOS-001
# phase 2: a failure, and the split; a row with no case, an engine line and no row line, the chunk green
cr p1c1 3 alpha "$C" ROW-001-a=pass ROW-002-T1=pass ROW-002-T2=pass; cr p2c1 1 beta "$C" ROW-001-a=fail:only\ here ROW-002-T1=pass ROW-002-T2=pass; cr p2c2 1 beta "$C" HOS-001=pass; rd
ln chunk p2c1 red 1; ln row p2c1 beta ROW-001 failed ROW-001-a; ln split ROW-001 alpha beta; ln chunk p2c2 green 1; ln row p2c2 beta HOS-001 passed; no row p2c2 beta RULE-001; ln engine beta 1 'could not run'
ln split HOS-001 beta alpha; [ "$(grep -c '^split' "$T/out")" = 2 ] || fail 'a split for a row failing nowhere'
# a refused report: absent, with its attempt and its refused line; another commit, an engine's file missing, the wrong role
cr p2c1 2 beta "$RR_H" ROW-001-a=pass ROW-002-T1=pass ROW-002-T2=pass; rd; ln chunk p2c1 absent 2; grep -q "^refused${TAB}req-$I-p2c1-2${TAB}the commit $RR_H is not the one asked for" "$T/out" || fail 'no refused line for another commit'; ln row p2c1 beta ROW-001 'not run'
cr p2c1 2 alpha "$C" ROW-001-a=pass ROW-002-T1=pass ROW-002-T2=pass; rd; grep -q "^refused${TAB}req-$I-p2c1-2${TAB}no whole cases file for beta" "$T/out" || fail 'no refused line for a missing engine'
i=req-$I-p2c1-2; rr_put "$i" results.txt "$(printf 'by: GR\ncommit: %s' "$C")"; rr_send "$i"; rd; grep -q "^refused${TAB}$i${TAB}the first line of results.txt is not by: TM" "$T/out" || fail 'no refused line for the wrong role'
cr p2c1 3 beta "$C" ROW-001-a=pass ROW-002-T1=pass ROW-002-T2=pass; rd; ln chunk p2c1 green 3; grep -q '^refused' "$T/out" && fail 'an older refused attempt still said'
# not run: a case the row's newest accepted head report named that the close lacks; a newer accepted head of a parallel step, no ancestor of the close's commit, changes nothing
git -C "$T/w" checkout -q -b side "$RR_base"; echo side > "$T/w/side.txt"; git -C "$T/w" add -A; rr_git -C "$T/w" commit -qm side; SD=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/p/.vid/code" side; S12=$(printf %s "$SD" | cut -c1-12)
A=pr-4-$RR_H12-1; rr_put "$A" results.txt "$(printf 'by: TM\ncommit: %s' "$RR_H")"; rr_put "$A" cases-alpha.xml "$(rr_cases ROW-001-a=pass ROW-001-b=pass ROW-002-T1=pass ROW-002-T2=pass)"; rr_send "$A"
A=pr-5-$S12-1; rr_put "$A" results.txt "$(printf 'by: TM\ncommit: %s' "$SD")"; rr_put "$A" cases-alpha.xml "$(rr_cases ROW-001-a=pass ROW-001-b=pass ROW-001-c=pass)"; rr_send "$A"
printf '2031-01-01T00:00:00Z\t4\t%s\tROW-001\taccepted\n2031-01-01T00:00:00Z\t4\t%s\tROW-002-T1\tfailing\n2031-01-02T00:00:00Z\t5\t%s\tROW-001\taccepted\n' "$RR_H12" "$RR_H12" "$S12" > .vid/decide/log
cr p1c1 4 alpha "$C" ROW-001-a=pass ROW-001-b=pass ROW-002-T1=pass ROW-002-T2=pass; rd; ln row p1c1 alpha ROW-001 passed; ln chunk p1c1 green 4
cr p1c1 4 alpha "$C" ROW-001-a=pass ROW-002-T1=pass ROW-002-T2=pass; rd; ln row p1c1 alpha ROW-001 'not run'; ln chunk p1c1 incomplete 4; ln row p2c1 beta ROW-001 passed
# a report broken past reading: still exit 0
i=req-$I-p1c3-2; rr_put "$i" results.txt "$(printf 'by: TM\ncommit: %s' "$C")"; : > "$T/r/$i/cases-alpha.xml"; rr_send "$i"; rd; ln chunk p1c3 absent 2
# phase 2: a row the accepted head report ran in that engine, with no case at all in the close, is not run, never an engine line
A=pr-4-$RR_H12-1; rr_put "$A" cases-beta.xml "$(rr_cases ROW-001-a=pass ROW-001-b=pass ROW-002-T1=pass ROW-002-T2=pass)"; rr_send "$A"
cr p2c1 4 beta "$C" ROW-002-T1=pass ROW-002-T2=pass; rd; ln row p2c1 beta ROW-001 'not run'; ln chunk p2c1 incomplete 4
# R3: the step's asks by number, the newest read; an ask with no ask file yet is no ask
mkdir -p .vid/decide/close/S02/1 .vid/decide/close/S02/2 .vid/decide/close/S02/3; sed "s/^issue${TAB}30\$/issue${TAB}31/" .vid/decide/close/S01/ask > .vid/decide/close/S02/1/ask; cp .vid/decide/close/S01/ask .vid/decide/close/S02/2/ask
sh "$R" close --step S02 > "$T/out" 2>&1 || fail 'the numbered asks could not be read'; cmp -s "$T/out" .vid/decide/close/S02/2/read || fail 'the newest ask with an ask file is not the one read'; no chunk p1c1 absent; [ ! -f .vid/decide/close/S02/1/read ] || fail 'an older ask was read'
# v0.26.10.25.5 R4: a row landed since the ask was asked leaves the read
printf 'ROW-002 abcdef123456 2099-01-01T00:00:00Z\n' > .vid/decide/landed; rd; no row p1c1 alpha ROW-002; grep -q "^row${TAB}p1c1${TAB}alpha${TAB}ROW-001${TAB}" "$T/out" || fail 'the other rows left too'; rm -f .vid/decide/landed
exit 0
