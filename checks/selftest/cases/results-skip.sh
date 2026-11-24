#!/bin/sh
# Purpose: selftest case — one bad report branch stops nothing (FB-3 A2), github.sh results-fetch on the fake gh. Of a report branch its
# own folder alone is read and fetched, whatever else the branch holds: a report branch made from main with its folder is read whole; one
# with the code and no folder, one with its files loose at the top and one whose name is a file there are left out, each a line of
# .vid/round/reports-skipped (id, commit, author, date, why), and the fetch passes; a folder holding a link, an executable file and a
# pointer to another repository is read, nothing followed. No tree or file of .vid/code is the code's, no name of the code is in any of
# its trees. A left-out branch put right is read; one gone bad loses its earlier report; a deleted one leaves the list; a second fetch
# asks for the left-out ones alone. An id holds any plain character git allows
# in a branch's last part; a name with a slash or past plain text is left out, its why saying so. A read GitHub fails is refused in its words, the copy and the list as they were. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "results-skip: $*" >&2; cat "$T/out" .vid/round/reports-skipped >&2 2>/dev/null; exit 1; }
g() { git -c user.name='A Person' -c user.email=t@t "$@"; }
rf() { RC=0; sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || RC=$?; }
git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main
g init -q "$T/w"; cd "$T/w"; git symbolic-ref HEAD refs/heads/main; mkdir -p deepcode/inner; echo 'secret code' > deepcode/inner/app-secret.py; echo top > topsecret.txt; g add -A; g commit -q -m code; git push -q "$T/code.git" main; M=$(git rev-parse main)
# put <id> <how>: a branch made from main (its code beside it): with its folder, or the form named
put() { git checkout -q -f -B "b-$1" main; rm -rf "$1"; case $2 in
    folder) mkdir "$1"; printf 'by: A Person\ncommit: %s\n' "$M" > "$1/results.txt"; printf '<testsuite><testcase name="x ROW-001"/></testsuite>' > "$1/suite.xml" ;;
    none) echo more >> topsecret.txt ;; loose) echo loose > results.txt ;; file) echo a-file > "$1" ;;
    odd) mkdir "$1"; printf 'by: A Person\ncommit: %s\n' "$M" > "$1/results.txt"; ln -s ../topsecret.txt "$1/link"; printf '#!/bin/sh\n' > "$1/run.sh"; chmod +x "$1/run.sh"; git add -A "$1"; git update-index --add --cacheinfo "160000,$M,$1/sub" ;; esac
  git add "$1" topsecret.txt results.txt 2>/dev/null || git add -A .; [ "$2" != odd ] || git update-index --add --cacheinfo "160000,$M,$1/sub"; g commit -q -m "$1 $2"; git push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; git checkout -q -f main; git clean -qfdx; }
put red-1-1 folder; put red-7-1 none; put step-8-1 loose; put pr-9-1 file; put unit-10-1 odd
mkdir -p "$T/v/.vid/tw"; cd "$T/v"; : > .vid/RUN-STATE.md; printf 'repo: owner/code\n' > .vid/tw/settings; gh_fake; CG='git --git-dir=.vid/code'; S=.vid/round/reports-skipped
rf; [ "$RC" = 0 ] || fail "with bad branches, results-fetch: exit $RC"
for i in red-1-1 unit-10-1; do [ "$($CG show "refs/heads/vid-results/$i:$i/results.txt" | head -n 1)" = 'by: A Person' ] || fail "the report $i was not read"; done
[ "$($CG ls-tree --name-only refs/heads/vid-results/red-1-1)" = red-1-1 ] && [ "$($CG ls-tree -r --name-only refs/heads/vid-results/red-1-1 | wc -l | tr -d ' ')" = 2 ] || fail 'the report made from main is not its folder alone'
[ "$($CG log -1 --format=%s refs/heads/vid-results/red-1-1)" = "vid-report: $(git -C "$T/code.git" rev-parse refs/heads/vid-results/red-1-1)" ] && [ "$($CG log -1 --format=%ct refs/heads/vid-results/red-1-1)" = "$(git -C "$T/code.git" log -1 --format=%ct refs/heads/vid-results/red-1-1)" ] || fail "a report's ref does not name its branch's commit and time"
[ "$($CG cat-file -p refs/heads/vid-results/unit-10-1:unit-10-1/link)" = ../topsecret.txt ] || fail 'the link was followed'
for i in red-7-1 step-8-1 pr-9-1; do ! $CG rev-parse -q --verify "refs/heads/vid-results/$i" > /dev/null || fail "$i is read"
  grep -q "^$i	$(git -C "$T/code.git" rev-parse "refs/heads/vid-results/$i")	A Person	[0-9T:+Z-]*	." "$S" || fail "$i is not in the list with its commit, author, date and why"; done
[ "$(cut -f1 "$S" | tr '\n' ' ')" = 'pr-9-1 red-7-1 step-8-1 ' ] && [ "$(grep '^red-7-1' "$S" | cut -f5)" = 'it has no folder red-7-1' ] && [ "$(grep '^pr-9-1' "$S" | cut -f5)" = 'pr-9-1 is a file there, not a folder' ] || fail 'the list is not the three, each with its why'
clean() { for t in $($CG cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' | awk '$2 == "tree" { print $1 }'); do ! $CG ls-tree "$t" | grep -E 'deepcode|topsecret|app-secret' > "$T/out" || fail 'a name of the code is in a tree of .vid/code'; done
  for b in $($CG cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' | awk '$2 == "blob" { print $1 }'); do ! $CG cat-file -p "$b" | grep -qE 'secret code|^top$' || fail 'a file of the code is in .vid/code'; done; }
clean
# a second fetch asks for the left-out ones alone
: > "$T/gh/graphql-log"; rf; [ "$RC" = 0 ] && [ "$(sort "$T/gh/graphql-log" | tr '\n' ' ')" = 'pr-9-1 red-7-1 step-8-1 ' ] || { cp "$T/gh/graphql-log" "$T/out"; fail 'a second fetch asked for another list'; }
# an id of any plain character git allows; a slash or a letter past plain text: left out with its why
cd "$T/w"; put 'ci+linux-1' folder; put "a!#\$%&'(),;=@b{c}|\`-2" folder; put 'sub/unit-3' none; put 'é-4' folder; cd "$T/v"; rf; [ "$RC" = 0 ] || fail "ids of other characters: exit $RC"
for i in 'ci+linux-1' "a!#\$%&'(),;=@b{c}|\`-2"; do [ "$($CG show "refs/heads/vid-results/$i:$i/results.txt" | head -n 1)" = 'by: A Person' ] || fail "the report $i was not read"; done
for i in sub/unit-3 é-4; do grep -F "$i	" "$S" | cut -f5 | grep -q '^its name holds ' || fail "$i is not left out for its name"; git -C "$T/code.git" update-ref -d "refs/heads/vid-results/$i"; done; clean; rf
# GitHub fails: refused in its words, the copy and the list as they were
cd "$T/w"; put red-1-2 folder; cd "$T/v"; cp "$S" "$T/s0"; $CG for-each-ref > "$T/r0"; : > "$T/gh/graphql-fail"; rf; [ "$RC" = 1 ] && grep -q 'refused — .*HTTP 502' "$T/out" || fail "GitHub's failure was not refused in its words: exit $RC"
cmp -s "$S" "$T/s0" && $CG for-each-ref | cmp -s - "$T/r0" || fail "GitHub's failure changed the copy or the list"; rm -f "$T/gh/graphql-fail"
# put right: read; gone bad: its earlier report dropped; deleted: off the list
cd "$T/w"; put red-7-1 folder; put red-1-1 none; cd "$T/v"; git -C "$T/code.git" update-ref -d refs/heads/vid-results/pr-9-1; rf; [ "$RC" = 0 ] || fail "the third fetch: exit $RC"
$CG rev-parse -q --verify refs/heads/vid-results/red-7-1 > /dev/null || fail 'a branch put right is not read'; ! $CG rev-parse -q --verify refs/heads/vid-results/red-1-1 > /dev/null || fail 'a branch gone bad keeps its earlier report'
[ "$(cut -f1 "$S" | tr '\n' ' ')" = 'red-1-1 step-8-1 ' ] || fail 'the list is not the branches that are bad now'; clean
exit 0
