#!/bin/sh
# Purpose: selftest case — a grade or a sort whose lines end with CR LF is taken (FB-8 E3), devagent/test-manager/run.sh on the fixture
# project with a local bare repository as origin. A head's grade, its second reader's, a stage's grade, a sort and the sort's lines, each
# with CR LF, are pushed with no CR at a line's end, the file given left as it is; a file with LF alone is pushed byte for byte, a CR inside a
# line and a last line without its end included. A CR LF grade of another commit is still refused, and a CR LF sort, in the words of the files given. Nothing is left in the temporary
# folder. Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$CHECKS/../devagent/test-manager/run.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; mkdir "$T/home" "$T/tmp"; HOME=$T/home; TMPDIR=$T/tmp; export HOME TMPDIR
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "grade-crlf: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"
S=$T/work/dev-setup.txt; H=$(printf %s "$SP_C" | cut -c1-12); O="git -C $T/origin.git"; CR=$(printf '\r')
run() { RC=0; sh "$R" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "$* was refused ($RC)"; }
crlf() { awk '{ printf "%s\r\n", $0 }' "$1" > "$2"; }
at() { $O show "vid-results/$1" > "$T/got" || fail "no $1"; }
same() { at "$1"; cmp -s "$T/got" "$2" || fail "$3 is not the LF file: $(od -c "$T/got" | head -n 4)"; }
# a head's grade, alone and by two readers
printf 'by: GR\ncommit: %s\nROW-001 kept\nROW-002 breached test — a word\nfinding: a thing\n' "$SP_C" > g.txt; crlf g.txt gc.txt; cp gc.txt gc.keep; G=grade-pr-1-$H
run grade --setup "$S" --ask "$G" --file g.txt; run grade --setup "$S" --ask "$G" --file gc.txt; same "$G-1:$G-1/grade.txt" g.txt 'the LF grade'; same "$G-2:$G-2/grade.txt" g.txt 'the CR LF grade'
cmp -s gc.txt gc.keep || fail "the grader's own file was changed"
printf 'by: GR\ncommit: %s\nROW-001 kept\nROW-002 kept\n' "$SP_C" > h.txt; crlf h.txt hc.txt
run grade --setup "$S" --ask "$G" --file g.txt --second h.txt; run grade --setup "$S" --ask "$G" --file gc.txt --second hc.txt; run grade --setup "$S" --ask "$G" --file g.txt --second hc.txt
at "$G-3:$G-3/grade.txt"; cp got joined; grep -q 'ROW-002 breached test' joined || fail 'the join of the LF files'; same "$G-4:$G-4/grade.txt" joined 'the join of two CR LF files'; same "$G-5:$G-5/grade.txt" joined 'the join of an LF and a CR LF file'
# a stage's grade
printf 'by: GR\ncommit: %s\nREQ-1 pass — a word\nREQ-2 partial — a word\nfinding: bug high — a thing\n' "$SP_C" > s.txt; crlf s.txt sc.txt
run grade --setup "$S" --ask grade-13 --commit "$SP_C" --reqs 'REQ-1 REQ-2' --file sc.txt; same 'grade-13-1:grade-13-1/grade.txt' s.txt "the stage's CR LF grade"
# a sort: its file, its lines, both
printf 'by: DM\ncommit: %s\nROW-002 breached test — a word\n' "$SP_C" > l.txt; crlf l.txt lc.txt; printf 'by: SR\ncommit: %s\nROW-002 test it — why — ROW-002 breached test — a word\n' "$SP_C" > o.txt; crlf o.txt oc.txt; A=sort-pr-1-$H
run sort --setup "$S" --ask "$A" --lines l.txt --file o.txt; run sort --setup "$S" --ask "$A" --lines l.txt --file oc.txt; run sort --setup "$S" --ask "$A" --lines lc.txt --file o.txt; run sort --setup "$S" --ask "$A" --lines lc.txt --file oc.txt
for k in 1 2 3 4; do same "$A-$k:$A-$k/sorted.txt" o.txt "sort $k"; done
# LF alone: byte for byte, a CR inside a line and a last line with no end
printf 'by: GR\ncommit: %s\nROW-001 kept%s here\nROW-002 kept' "$SP_C" "$CR" > i.txt; run grade --setup "$S" --ask "$G" --file i.txt; same "$G-6:$G-6/grade.txt" i.txt 'the LF file with a CR inside a line'
# what is refused stays refused
printf 'by: GR\r\ncommit: %040d\r\nROW-001 kept\r\n' 1 > b.txt; RC=0; sh "$R" grade --setup "$S" --ask "$G" --file b.txt > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'is not the grade of' "$T/out" || fail "a CR LF grade of another commit ($RC)"
sed 's/a word/another/' oc.txt > wc.txt; RC=0; sh "$R" sort --setup "$S" --ask "$A" --lines lc.txt --file wc.txt > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -qF 'the lines of wc.txt are not those of lc.txt, one for one' "$T/out" || fail "a refused CR LF sort does not name the files given ($RC)"
[ -z "$(ls -A "$T/tmp")" ] || fail "left in the temporary folder: $(ls -A "$T/tmp")"
echo 'grade-crlf: ok'
