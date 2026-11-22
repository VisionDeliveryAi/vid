#!/bin/sh
# Purpose: selftest case — FB-1 A1: the commit checks on in a ticket-mode spec repository. On the planner's toy
# (fixtures/planner-toy.sh: RUN-STATE at `mode: tickets`, rule rows owed census-armed with their census in words, a STAGES.md),
# with the plugin's checks/ copied in and the hooks path set, a BASELINE.md, a design pack with one marker, no CLAUDE.md, `.vid/`
# untracked and not ignored, and an untracked file outside it (so the inventory and census lane runs in a copy of the index): a
# one-word doc commit with the message template passes the real hooks. No court fails closed on CLAUDE.md, the census runs no
# rule row's words, and the lane copy reads ticket mode from the project's `.vid`. Env: CHECKS.
set -eu
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "hook-lane-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
pt_toy "$T/p" > /dev/null 2>&1; git init -q
grep -q '^mode: tickets' .vid/RUN-STATE.md || fail 'the toy is not in ticket mode'
grep -q '^rule | RULE-001 | .* | sites: .*owed: census-armed' INVENTORY.md || fail 'the toy has no census-armed rule row in words'
mkdir -p checks; cp -R "$CHECKS/." checks/; rm -f checks/selftest/cases/*.sh
printf '#!/bin/sh\n# Purpose: the toy'"'"'s one self-test case\nexit 0\n' > checks/selftest/cases/toy-case.sh
printf '# toy\n\n```vid-allowed-extensions\n.py .sh .md .yml .txt .html .css .xml .json\n```\n\n```vid-forbidden\nzq''xk\n```\n' > BASELINE.md
# the toy's own gaps closed, so only the mode is judged: the two cited test files, and the mail seam's probe classed
mkdir -p tests/invariants; printf '# Purpose: ROW-013\n' > tests/invariants/test_feed_repeat.py; printf '# Purpose: HOS-001\n' > tests/invariants/test_hostility_dupes.py
sed 's/^\(seam | SEAM-001 | .*\)| probe: owed |/\1| probe: unreachable-risk(credentials not-yet) |/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
grep -q '^seam | SEAM-001 .*probe: unreachable-risk' INVENTORY.md || fail "the mail seam's probe was not classed"
mkdir -p design/screens; printf '<!-- @screen P01 state=default -->\n<p>the digest</p>\n' > design/screens/p01.html
printf '# JobDigest\n\nThe notes.\n' > NOTES.md
rm -f CLAUDE.md .gitignore
g add -A -- . ':(exclude).vid'; g -c core.hooksPath=/dev/null commit -qm 'the toy, made by hand'
[ -z "$(git ls-files .vid)" ] || fail 'the toy tracks .vid/'
printf 'a helper the team keeps\n' > helper.txt
git config core.hooksPath checks/hooks
printf '# JobDigest\n\nThe notes, read.\n' > NOTES.md; g add NOTES.md
RC=0; VID_ROLE=fix g commit -q -m "$(printf 'A word in the notes\n\nREQs: none\nDecisions: none — nothing surprising\nSeams: none\n')" > "$T/out" 2>&1 || RC=$?
! grep -q 'CLAUDE.md missing' "$T/out" || fail 'a court failed closed on CLAUDE.md in ticket mode'
! grep -q 'command not found' "$T/out" || fail "the census ran a rule row's words"
[ "$RC" = 0 ] || fail "the one-word doc commit was refused ($RC)"
[ "$(git log -1 --format=%s)" = 'A word in the notes' ] || fail 'the commit is not HEAD'
echo 'hook-lane-tickets: ok'
