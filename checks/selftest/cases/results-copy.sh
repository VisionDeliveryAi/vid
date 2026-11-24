#!/bin/sh
# Purpose: selftest case — the decider's copy with no file of the code (0.26.10.28.4, 9.3 R5, M5), github.sh results-fetch on the fake gh, whose code
# repository honours a filter as GitHub does. The code repository holds a file, an empty file, two branches and a pull-request head; its first commit is
# empty. results-fetch makes .vid/code a partial copy with no stored address and an unborn HEAD: every report reads whole; a commit's presence, ancestry and
# first-parent count read as in a full copy; a code commit's tree is not there, and a code file's read fails with nothing fetched. A copy in the earlier,
# full form is replaced, saying so. With no report, the fetch passes and brings the commits. A report holding a file byte for byte a code file's, and an
# empty file, reads whole; a report pushed again reads its new version and the proof holds. FB-3 A2: a report branch with no folder of its own is left out. Refused, .vid/code
# removed: a server that ignores the filter (a main whose second commit removes every file included). vid-run holds the rule's section, "DevAgent's
# code", once, and vid-tickets and vid-plan point to it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "results-copy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.name=t -c user.email=t@t "$@"; }
GS=$CHECKS/github.sh; rf() { RC=0; sh "$GS" results-fetch > "$T/out" 2>&1 || RC=$?; }
git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main
g init -q "$T/w"; cd "$T/w"; git symbolic-ref HEAD refs/heads/main; g commit -q --allow-empty -m root; mkdir -p pkg; : > pkg/__init__.py; echo 'shared words' > shared.txt; echo 'secret code' > app.py
g add -A; g commit -q -m code1; git push -q "$T/code.git" main; M=$(git rev-parse main)
git checkout -q -b feat; echo more >> app.py; g commit -q -am feat1; git push -q "$T/code.git" feat; FE=$(git rev-parse feat)
git checkout -q -b pr main; echo pr > pr.py; git add pr.py; g commit -q -m pr1; git push -q "$T/code.git" HEAD:refs/pull/1/head; P=$(git rev-parse pr)
# rep <name> <parent|root> <file[=text]>…: a report, its folder alone
rep() { n=$1; b=$2; shift 2; rm -rf "$T/r"; mkdir -p "$T/r/$n"; for f in "$@"; do case $f in *=*) printf '%s\n' "${f#*=}" > "$T/r/$n/${f%%=*}" ;; *) : > "$T/r/$n/$f" ;; esac; done
  t=$(GIT_INDEX_FILE=$T/ix git --git-dir="$T/w/.git" --work-tree="$T/r" add -A . && GIT_INDEX_FILE=$T/ix git --git-dir="$T/w/.git" write-tree); rm -f "$T/ix"
  if [ "$b" = root ]; then c=$(echo "$n" | g --git-dir="$T/w/.git" commit-tree "$t"); else c=$(echo "$n" | g --git-dir="$T/w/.git" commit-tree "$t" -p "$b"); fi; git --git-dir="$T/w/.git" push -q -f "$T/code.git" "$c:refs/heads/vid-results/$n"; }
mkdir -p "$T/v/.vid/tw"; cd "$T/v"; : > .vid/RUN-STATE.md; printf 'repo: owner/code\n' > .vid/tw/settings; gh_fake
CG="git --git-dir=.vid/code"; pc() { $CG count-objects -v | awk '$1 == "count:" || $1 == "in-pack:" { s += $2 } END { print s }'; }
# no report yet: the commits come
rf; [ "$RC" = 0 ] || fail "with no report, results-fetch: exit $RC"; [ "$($CG rev-parse main)" = "$M" ] && $CG cat-file -e "$P^{commit}" || fail 'with no report, the commits did not come'
[ "$($CG config extensions.partialClone)" = vid-commits ] && [ -z "$($CG config remote.vid-commits.url || true)" ] && [ "$($CG symbolic-ref HEAD)" = refs/vid/none ] && ! $CG rev-parse -q --verify HEAD > /dev/null || fail 'the copy is not in its form'
# reports: a root one, one built on main with its folder alone, one sharing a file and an empty file with the code
rep pr-1-aaaaaaaaaaaa-1 root 'results.txt=by: TM'; rep req-5-p1c1-1 "$M" 'results.txt=by: TM' 'cases-alpha.xml=<testsuite/>'; rep grade-7-1 "$M" 'grade.txt=shared words' 'empty.txt'; rep deploy-9-1 "$FE" 'report.txt=outcome: failed start'
rf; [ "$RC" = 0 ] || fail "results-fetch with reports: exit $RC"
git clone -q --bare "$T/code.git" "$T/full.git"; git --git-dir="$T/full.git" fetch -q "$T/code.git" '+refs/heads/*:refs/heads/*' '+refs/pull/*/head:refs/pull/*/head'
reads() { D=$1; R() { git --git-dir="$D" "$@" 2>&1 && echo rc=0 || echo "rc=$?"; }
  R for-each-ref --format='%(refname) %(tree)' 'refs/heads/vid-results/*'
  for r in $(git --git-dir="$D" for-each-ref --format='%(refname:lstrip=3)' 'refs/heads/vid-results/*'); do R ls-tree -r --name-only "refs/heads/vid-results/$r"
    for f in $(git --git-dir="$D" ls-tree -r --name-only "refs/heads/vid-results/$r"); do R show "refs/heads/vid-results/$r:$f"; done; R log -1 --format=%ct "refs/heads/vid-results/$r"; done
  for c in "$M" "$FE" "$P"; do R rev-parse -q --verify "$c^{commit}"; R cat-file -e "$c^{commit}"; for o in "$M" "$FE" "$P"; do R merge-base --is-ancestor "$c" "$o"; done; done
  R rev-list --count --first-parent "$M..$FE"; R rev-list --count --first-parent "$M..$P"; }
reads "$T/full.git" > "$T/full.out"; reads .vid/code > "$T/new.out"; cmp -s "$T/full.out" "$T/new.out" || { diff "$T/full.out" "$T/new.out" > "$T/out" || true; fail 'a read differs from a full copy'; }
# no file of the code, and a failed read fetches nothing
n0=$(pc); ! $CG cat-file -e "main^{tree}" 2>/dev/null || fail "main's tree is in the copy"; ! $CG show main:app.py > /dev/null 2>&1 || fail 'a code file was read'
! $CG show "$FE:pkg/__init__.py" > /dev/null 2>&1 || fail 'an empty code file was read'; [ "$(pc)" = "$n0" ] || fail 'a failed read fetched'
# a report pushed again, and a new code commit: the new version whole, the proof held
cd "$T/w"; git checkout -q feat; echo again >> app.py; g commit -q -am feat2; git push -q "$T/code.git" feat; rep deploy-9-1 "$FE" 'report.txt=outcome: passed' 'staging.txt=staging: http://x'; cd "$T/v"
rf; [ "$RC" = 0 ] || fail "the second fetch: exit $RC"; [ "$($CG show refs/heads/vid-results/deploy-9-1:deploy-9-1/report.txt)" = 'outcome: passed' ] || fail 'a report pushed again reads its old version'
! $CG cat-file -e "refs/heads/feat^{tree}" 2>/dev/null || fail "feat's tree came with the second fetch"
# a report tagged on the server, then pushed again, reads its new version, its old files gone; a code branch named …/vid-results/… is no report
g --git-dir="$T/code.git" tag -a -m t r-old refs/heads/vid-results/deploy-9-1; rf; [ "$RC" = 0 ] && [ -z "$($CG tag)" ] || fail "a tag came, or the fetch failed: $RC"
cd "$T/w"; rep deploy-9-1 "$FE" 'report.txt=outcome: passed again'; cd "$T/v"; rf; [ "$RC" = 0 ] && [ "$($CG show refs/heads/vid-results/deploy-9-1:deploy-9-1/report.txt)" = 'outcome: passed again' ] || fail "a tagged report pushed again: $RC"
git --git-dir="$T/code.git" update-ref refs/pull/7/head refs/heads/vid-results/deploy-9-1; rf; cd "$T/w"; rep deploy-9-1 "$FE" 'report.txt=outcome: passed once more'; cd "$T/v"   # a pull head at a report's commit
rf; [ "$RC" = 0 ] && [ "$($CG show refs/heads/vid-results/deploy-9-1:deploy-9-1/report.txt)" = 'outcome: passed once more' ] || fail "a pull head left at a report's old commit: $RC"
git --git-dir="$T/code.git" update-ref refs/heads/ticket-4/vid-results/notes "$M"; rf; [ "$RC" = 0 ] || fail "a code branch named ticket-4/vid-results/notes broke the fetch: $RC"
! $CG cat-file -e "refs/heads/ticket-4/vid-results/notes^{tree}" 2>/dev/null || fail 'a code branch with vid-results in its name came with its files'
# an earlier, full copy is replaced
rm -rf .vid/code; git clone -q --bare "$T/code.git" .vid/code; rf; [ "$RC" = 0 ] && grep -q '^ViD github: .vid/code held DevAgent.s files, the earlier form — replaced by a copy that holds none' "$T/out" || fail "the earlier form: exit $RC"
! $CG cat-file -e "main^{tree}" 2>/dev/null || fail 'the replaced copy holds a code tree'
# a report branch holding the code and no folder of its own: left out (FB-3 A2), the rest fetched
rep req-5-p1c1-1 "$M" 'results.txt=by: TM'; cd "$T/w"; t=$(git rev-parse "$M^{tree}"); git push -q -f "$T/code.git" "$(echo x | g commit-tree "$t" -p "$M"):refs/heads/vid-results/red-3-1"; cd "$T/v"
rf; [ "$RC" = 0 ] && grep -q "^red-3-1	.*	it has no folder red-3-1$" .vid/round/reports-skipped && ! $CG rev-parse -q --verify refs/heads/vid-results/red-3-1 > /dev/null || fail "a report branch with no folder: exit $RC"
git --git-dir="$T/code.git" update-ref -d refs/heads/vid-results/red-3-1
# a server that ignores the filter: refused, no copy left; also with a main whose tip's tree is empty
: > "$T/gh/no-filter"; rm -rf .vid/code; rf; [ "$RC" != 0 ] && grep -q "refused — the fetch brought DevAgent's files (" "$T/out" && [ ! -e .vid/code ] || fail "a server ignoring the filter: exit $RC"
cd "$T/w"; git checkout -q main; git rm -rq .; g commit -q -m 'all gone'; git push -q "$T/code.git" main; cd "$T/v"; [ -z "$(git --git-dir="$T/code.git" ls-tree main)" ] || fail 'the fixture: main is not empty'
rf; [ "$RC" != 0 ] && [ ! -e .vid/code ] || fail "a server ignoring the filter, main's tip empty: exit $RC"
rm -f "$T/gh/no-filter"; rf; [ "$RC" = 0 ] || fail "the filter honoured again: exit $RC"
# the rule in one place: vid-run's section, once; vid-tickets and vid-plan point to it (where skills/ is here)
K=$CHECKS/../skills; if [ -d "$K/vid-run" ]; then [ "$(grep -c "^## DevAgent's code$" "$K/vid-run/SKILL.md")" = 1 ] && grep -q '`.vid/code`, made by `sh checks/github.sh results-fetch`, holds the reports and the commits, with no file of the code' "$K/vid-run/SKILL.md" || fail "vid-run does not hold the rule's section once"
  for k in vid-tickets vid-plan; do grep -qF "ViD never writes, reads or runs DevAgent's code (vid-run, 'DevAgent's code')" "$K/$k/SKILL.md" || fail "$k does not point to the rule"; done
  ! grep -nE 'merge changed|team code beyond|reads no team code' "$K/vid-run/SKILL.md" "$K/vid-tickets/SKILL.md" "$K/vid-plan/SKILL.md" > "$T/out" || fail 'a skill still lets ViD read what a merge changed'; fi
echo 'results-copy: ok'
