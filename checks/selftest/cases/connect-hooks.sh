#!/bin/sh
# Purpose: selftest case — FB-1 A1: the connect switches the commit checks on once they pass (connect.sh hooks, run by start
# right after the refresh and the WSL notice). On GitHub manual's toy (fixtures/manual.sh) in ticket mode, with a BASELINE.md, no
# CLAUDE.md and `core.hooksPath` unset: while STAGES.md holds a `row:` line placing a protection row, `connect.sh start` leaves
# the hooks path unset, prints `refused by stages` and the line saying the next call switches them on, and still ends ready;
# with that line removed and committed, the next start sets `core.hooksPath` to checks/hooks and says what a commit made by
# hand now needs. A second start with nothing changed since a refusal prints the same lines from .vid/next/hooks-off and runs
# no court (a logging `sh` first on the PATH sees none); the pass removes that file.
# The line-endings check runs first: an untracked spec file (DESIGN-AMENDMENT-BRIEF.md) saved with CR LF is `refused by
# line-endings` and the hooks stay off; the same file fixed to LF, still untracked, changes the kept refusal's key, so the next
# start runs the courts again and switches the checks on. A repair staged alone (the index fixed, the working tree still
# differing from it, so the status and the diff from HEAD are as they were) changes the key too. The entry run on its own, `connect.sh hooks`, exits 0 with a refusal and the hooks left unset, then,
# the refusal corrected, switches them on. With the hooks path set to another tool's folder, a start leaves it as it is and prints no hooks line.
# Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "connect-hooks: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
C() { RC=0; sh "$CHECKS/connect.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
hp() { git config --get core.hooksPath || true; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
gh repo create owner/vid-state --private > /dev/null
printf '# toy\n\n```vid-allowed-extensions\n.py .sh .md .yml .txt .html .css .xml .json\n```\n\n```vid-forbidden\nzq''xk\n```\n' > BASELINE.md
rm -f CLAUDE.md
# the toy's own gaps closed, so only the mode is judged: the two cited test files, and the mail seam's probe classed
mkdir -p tests/invariants; printf '# Purpose: ROW-013\n' > tests/invariants/test_feed_repeat.py; printf '# Purpose: HOS-001\n' > tests/invariants/test_hostility_dupes.py
sed 's/^\(seam | SEAM-001 | .*\)| probe: owed |/\1| probe: unreachable-risk(credentials not-yet) |/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
grep -q '^seam | SEAM-001 .*probe: unreachable-risk' INVENTORY.md || fail "the mail seam's probe was not classed"
grep -q '^hostility | HOS-004 | .*protects: RULE-001' INVENTORY.md || fail 'the toy has no HOS-004 protecting RULE-001'
awk '/^```vid-stages/ { print; print "row: HOS-004 -> STAGE-2"; next } { print }' STAGES.md > "$T/s" && cat "$T/s" > STAGES.md
grep -qx 'row: HOS-004 -> STAGE-2' STAGES.md || fail 'the row: line was not planted'
git add -A; git -c core.hooksPath=/dev/null commit -qm 'the toy: a baseline, and a protection row placed by hand'
[ -z "$(hp)" ] || fail 'the toy starts with a hooks path set'
# a protection row placed by a row: line: refused by stages, the call goes on
C start; cp "$T/out" "$T/out0"; [ "$RC" = 0 ] && grep -qx 'connect: ready' "$T/out" || fail "with the commit checks refusing, the start did not end ready ($RC)"
[ -z "$(hp)" ] || fail "with stages refusing, the start set core.hooksPath to $(hp)"
grep -q '^connect hooks: the commit checks are off — refused by stages: ' "$T/out" || fail 'the start printed no refused by stages line'
grep -qx 'connect hooks: close these and the next call switches them on' "$T/out" || fail 'the start did not say the next call switches them on'
n=$(grep -n '^connect hooks:' "$T/out" | head -n 1 | cut -d: -f1); r=$(grep -n '^connect refresh:' "$T/out" | head -n 1 | cut -d: -f1)
[ -n "$r" ] && [ "$n" -gt "$r" ] || fail 'the hooks lines do not follow the refresh'
grep -q '^connect hooks: .*refused by \(placement\|design-cite\|inventory\|census\)' "$T/out" && fail 'a ticket-mode court with no CLAUDE.md refused'
C end; [ "$RC" = 0 ] || fail "the end exited $RC"
# nothing changed since the refusal: the kept lines, no court run
[ -s .vid/next/hooks-off ] || fail 'the refusal was not kept in .vid/next/hooks-off'
grep '^connect hooks:' "$T/out0" > "$T/h0" 2>/dev/null || :
mkdir -p "$T/bin"; printf '#!/bin/sh
case "$1" in checks/*.sh) echo "$1" >> "%s/courts.log" ;; esac
exec /bin/sh "$@"
' "$T" > "$T/bin/sh"; chmod +x "$T/bin/sh"
: > "$T/courts.log"; RC=0; PATH="$T/bin:$PATH" sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the second start exited $RC"
grep '^connect hooks:' "$T/out" > "$T/h1" || :; cmp -s "$T/h0" "$T/h1" || { paste "$T/h0" "$T/h1" >&2; fail 'the second start, nothing changed, printed other hooks lines'; }
! grep -qxE 'checks/(placement|conformance|imports|seams|stages|inventory|census|design-cite|prd|harness)\.sh' "$T/courts.log" || fail "the second start, nothing changed, ran a court: $(tr '\n' ' ' < "$T/courts.log")"
grep -q . "$T/courts.log" || fail 'the logging sh saw no call: the scene proves nothing'
C end
# the line removed and committed: the next start switches them on
grep -vx 'row: HOS-004 -> STAGE-2' STAGES.md > "$T/s"; cat "$T/s" > STAGES.md
git add STAGES.md; git -c core.hooksPath=/dev/null commit -qm 'the protection row unplaced (A-001)'
# a spec file with CR LF, untracked: every court passes, the line-endings check refuses
printf '# Amendment brief\r\n\r\nNone yet.\r\n' > DESIGN-AMENDMENT-BRIEF.md
C start; [ "$RC" = 0 ] || fail "with a CR LF spec file the start exited $RC"
grep -q '^connect hooks: the commit checks are off — refused by line-endings: .*DESIGN-AMENDMENT-BRIEF.md' "$T/out" || fail 'a CR LF spec file is not refused by line-endings'
[ -z "$(hp)" ] || fail "with a CR LF spec file the start set core.hooksPath to $(hp)"
[ "$(grep -c '^connect hooks: .* refused by ' "$T/out")" = 1 ] || fail 'beside line-endings another court refused'
C end
# the file fixed, still untracked: the key changes, the courts run again
printf '# Amendment brief\n\nNone yet.\n' > DESIGN-AMENDMENT-BRIEF.md
C start; [ "$RC" = 0 ] || fail "the start exited $RC"
[ "$(hp)" = checks/hooks ] || fail "with every court passing, the start left core.hooksPath at '$(hp)'"
[ ! -e .vid/next/hooks-off ] || fail 'the pass left .vid/next/hooks-off'
grep -qx 'connect hooks: the commit checks are on; a commit made by hand now needs the message lines REQs:, Decisions: and Seams:' "$T/out" || fail 'the start did not say the commit checks are on'
C end
# another tool's hooks path: left as it is, and nothing said
git config core.hooksPath .othertool/hooks
C start; [ "$RC" = 0 ] || fail "with another hooks path the start exited $RC"
[ "$(hp)" = .othertool/hooks ] || fail "the start changed another tool's hooks path to '$(hp)'"
! grep -q '^connect hooks:' "$T/out" || fail 'with a hooks path set the start printed a hooks line'
C end
# a repair staged alone: STAGES.md's index copy refused, then fixed, the working tree's copy the same throughout
git config --unset core.hooksPath; cp STAGES.md "$T/st0"
{ awk '/^```vid-stages/ { print; print "row: HOS-004 -> STAGE-2"; next } { print }' "$T/st0"; echo '<!-- staged -->'; } > STAGES.md; git add STAGES.md
{ cat "$T/st0"; echo '<!-- a note in the working tree -->'; } > STAGES.md
C start; [ "$RC" = 0 ] && grep -q '^connect hooks: the commit checks are off — refused by stages: ' "$T/out" || fail "a refused staged STAGES.md was not refused by stages ($RC)"
[ -z "$(hp)" ] || fail "with the staged STAGES.md refused the start set core.hooksPath to $(hp)"
C end; git status --porcelain -- STAGES.md > "$T/ps0"
{ cat "$T/st0"; echo '<!-- staged -->'; } > "$T/st1"; git update-index --cacheinfo "100644,$(git hash-object -w "$T/st1"),STAGES.md"
git status --porcelain -- STAGES.md > "$T/ps1"; cmp -s "$T/ps0" "$T/ps1" || fail 'the scene changed the status, so it proves nothing'
C start; [ "$RC" = 0 ] || fail "after the staged repair the start exited $RC"
[ "$(hp)" = checks/hooks ] || fail "after a repair staged alone the start left core.hooksPath at '$(hp)' (the stale refusal replayed)"
C end
# the entry on its own: a refusal, exit 0, the hooks unset; corrected, the hooks on
git config --unset core.hooksPath; printf '# Amendment brief\r\n\r\nNone yet.\r\n' > DESIGN-AMENDMENT-BRIEF.md
C hooks; [ "$RC" = 0 ] || fail "connect.sh hooks with a refusal exited $RC"
grep -q '^connect hooks: the commit checks are off — refused by line-endings: ' "$T/out" || fail 'connect.sh hooks printed no refusal'
[ -z "$(hp)" ] || fail "connect.sh hooks with a refusal set core.hooksPath to $(hp)"
printf '# Amendment brief\n\nNone yet.\n' > DESIGN-AMENDMENT-BRIEF.md
C hooks; [ "$RC" = 0 ] || fail "connect.sh hooks, the refusal corrected, exited $RC"
[ "$(hp)" = checks/hooks ] && grep -qx 'connect hooks: the commit checks are on; a commit made by hand now needs the message lines REQs:, Decisions: and Seams:' "$T/out" || fail "connect.sh hooks, the refusal corrected, did not switch the checks on ('$(hp)')"
echo 'connect-hooks: ok'
