#!/bin/sh
# Purpose: selftest case — the dev side's decisions wait while a spec file the commit hook refuses for is changed and not committed
# (FB-7 D2). `decisions.sh record` makes the hook's own two tests first: a law file (INVENTORY.md, named by checks/lawfiles) changed
# and not staged, or a file under design/ untracked, is `decisions unread <key>: <files> hold changes HEAD does not`, for a pull
# request's decisions and for a deploy's; nothing is kept, no event is written, DECISIONS.md and HEAD stay as they are, and the draft
# is left in the folder. So it is when the commit is refused for another reason while a spec file differs from HEAD: a PRD.md the PRD
# court refuses half-written, or one saved with Windows line endings (no change to git, its endings pinned). The folder clean again,
# the next record writes them. A file the hook does not refuse for (PRD.md changed, an
# untracked note) holds nothing; a DECISIONS.md HEAD does not hold still waits. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "decisions-dirty: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
printf '# stub lawfiles\nINVENTORY.md vid-inventory\n' > checks/lawfiles; mkdir -p design; echo a > design/a.md; git add -A checks design; g commit -qm law --no-verify
H0=$(git rev-parse HEAD)
dpr_pr 7 3 'ticket: #3

Decisions:
- notes sort by their last change | why: what users look for'
# a deploy's report too, read as dp-r2-deploy-dirty reads it
git init -q --bare .vid/code; git init -q "$T/w"; echo a > "$T/w/a"; git -C "$T/w" add a; g -C "$T/w" commit -qm a; C=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/v/.vid/code" HEAD:refs/heads/main
mkdir -p "$T/x/deploy-11-1"; printf 'by: DP\ncommit: %s\ndecision: the staging seed is the synthetic set | why: no customer data on staging\noutcome: passed\n' "$C" > "$T/x/deploy-11-1/report.txt"
printf '<testsuite name="deploy"><testcase name="checkout"/></testsuite>\n' > "$T/x/deploy-11-1/deploy.xml"; printf 'staging: http://127.0.0.1:47100\ndiffers: none\nseed: synthetic\n' > "$T/x/deploy-11-1/staging.txt"
for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done > "$T/x/deploy-11-1/duties.txt"
git init -q "$T/x"; git -C "$T/x" add -A; g -C "$T/x" commit -qm r; git -C "$T/x" push -q -f "$T/v/.vid/code" HEAD:refs/heads/vid-results/deploy-11-1
mkdir -p .vid/decide/stage/1/1/d1; printf 'issue\t11\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/ask; printf 'issue\t11\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/d1/ask
sh checks/results.sh deploy --stage 1 > "$T/out" 2>&1 || fail 'the reader failed'
waits() { # $1 the files the line names, $2 the scene
  dpr_rec; [ "$RC" = 0 ] || fail "$2: record exited $RC"
  for k in pr=7 deploy=deploy-11-1; do grep -qxF "decisions unread $k: $1 hold changes HEAD does not" "$T/out" || fail "$2: no line 'decisions unread $k: $1 hold changes HEAD does not'"; done
  if grep -q '^decisions-recorded ' .vid/metrics-events 2>/dev/null; then fail "$2: an event was kept: $(grep '^decisions-recorded ' .vid/metrics-events | paste -sd ';' -)"; fi
  [ "$(git rev-parse HEAD)" = "$H0" ] || fail "$2: a commit was made"
  git diff --quiet HEAD -- DECISIONS.md || fail "$2: DECISIONS.md is not as HEAD has it"; }
printf '\n<!-- a draft being written -->\n' >> INVENTORY.md
waits INVENTORY.md 'a draft in the folder'; waits INVENTORY.md 'a draft in the folder, again'
grep -q 'a draft being written' INVENTORY.md || fail 'the draft was not left in the folder'
echo b > design/b.md; waits 'INVENTORY.md design/b.md' 'a draft and a new design file'
git checkout -q HEAD -- INVENTORY.md; waits design/b.md 'a new design file alone'; rm design/b.md
# a spec file the hook refuses for by a court, or for its line endings: the commit refused, nothing kept
printf '#!/bin/sh\n# Purpose: stub court prd\n! grep -q HALF PRD.md || { echo "ViD prd: refused - half a sentence" >&2; exit 1; }\n' > checks/prd.sh; cp "$CHECKS/eol.sh" checks/; sh checks/eol.sh write > /dev/null
git add -A checks .gitattributes; g commit -qm law2 --no-verify; H0=$(git rev-parse HEAD)
echo 'HALF a sent' >> PRD.md; waits PRD.md 'a half-written PRD.md'; git checkout -q HEAD -- PRD.md
awk '{ printf "%s\r\n", $0 }' PRD.md > "$T/crlf"; cat "$T/crlf" > PRD.md; waits PRD.md 'a PRD.md with Windows line endings'; git show HEAD:PRD.md > PRD.md
# DECISIONS.md changed itself: as before
printf 'x\n' >> DECISIONS.md; dpr_rec; grep -qx 'decisions unread pr=7: DECISIONS.md holds changes HEAD does not' "$T/out" || fail 'a changed DECISIONS.md does not wait as before'
git checkout -q HEAD -- DECISIONS.md
# the folder clean, but for what the hook does not refuse for: both recorded
printf '\nA sentence being written.\n' >> PRD.md; echo n > a-note.md
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC with the folder put back"
for k in pr=7 deploy=deploy-11-1; do grep -q "^decisions recorded $k n=1 " "$T/out" || fail "the folder put back, $k was not recorded"; grep -q "^decisions-recorded $k n=1 at=" .vid/metrics-events || fail "no event for $k"; done
git show HEAD:DECISIONS.md | grep -q 'the staging seed is the synthetic set' && git show HEAD:DECISIONS.md | grep -q 'notes sort by their last change' || fail 'HEAD'"'"'s DECISIONS.md does not hold both'
[ "$(git diff --name-only "$H0" HEAD)" = DECISIONS.md ] || fail 'the commits hold more than DECISIONS.md'
echo 'decisions-dirty: ok'
