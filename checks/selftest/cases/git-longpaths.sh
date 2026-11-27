#!/bin/sh
# Purpose: selftest case — ViD's own deep paths and git's path-length limit on Windows (FIX-BATCH-T2 §2, B-13). There is no
# Windows here, so a stand-in git first on PATH refuses as Git for Windows does: an add before it runs when its work tree
# holds a file past the limit; a commit, checkout, merge, clone, reset or read-tree after, when the index it leaves holds a
# path longer than VID_TEST_PATHMAX; each only when core.longpaths is not true for that repository: it says "Filename too long" and exits 128. Scenes: (a) share-push of a bundle holding a deep path;
# (b) connect.sh start on a ticket-mode project with no checks/ committed, whose refresh adds ViD's deepest file, and
# core.longpaths set for the project after; (c) every git clone in checks/*.sh carries -c core.longpaths=true;
# (d) vid-init's step 6 sets it (skipped with no skills beside); (e) state-save of records holding a deep path, which
# its tree must hold (the save's add was never checked, so a refused one dropped records without a word);
# (f) state-restore into an existing project whose saved commit adds a deep path. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE VID_TEST_PATHMAX 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "git-longpaths: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
RG=$(command -v git); mkdir -p "$T/sbin"
cat > "$T/sbin/git" <<SG
#!/bin/sh
# the stand-in: the real git, then the length check on the index it leaves
RG='$RG'
SG
cat >> "$T/sbin/git" <<'SG'
q() { printf "'%s' " "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
G=''; while [ $# -gt 0 ]; do case $1 in -C|-c) G="$G$(q "$1")$(q "$2")"; shift 2 ;; --*=*|--no-*|--bare|--literal-pathspecs|-P) G="$G$(q "$1")"; shift ;; *) break ;; esac; done
sub=${1:-}; A=''; for a in "$@"; do A="$A$(q "$a")"; done
# an add is refused before it runs, as Git for Windows refuses it: its work tree holds a file past the limit
if [ "$sub" = add ] && [ -n "${VID_TEST_PATHMAX:-}" ] && [ "$(eval "\"\$RG\" $G config --bool --get core.longpaths" 2>/dev/null || true)" != true ]; then
  top=$(eval "\"\$RG\" $G rev-parse --show-toplevel" 2>/dev/null || true)
  if [ -n "$top" ]; then f=$(cd "$top" && find . -type f ! -path './.git/*' | sed 's|^\./||' | awk -v M="$VID_TEST_PATHMAX" 'length($0) > M { print; exit }')
    [ -z "$f" ] || { echo "error: open(\"$f\"): Filename too long" >&2; exit 128; }; fi; fi
eval "\"\$RG\" $G $A"; rc=$?
[ "$rc" = 0 ] && [ -n "${VID_TEST_PATHMAX:-}" ] || exit $rc
case $sub in add|commit|checkout|merge|clone|reset|read-tree) ;; *) exit 0 ;; esac
if [ "$sub" = clone ]; then d=''; for a in "$@"; do d=$a; done; G="$G$(q -C)$(q "$d")"; fi
lp=$(eval "\"\$RG\" $G config --bool --get core.longpaths" 2>/dev/null || true)
[ "$lp" != true ] || exit 0
f=$(eval "\"\$RG\" $G ls-files" 2>/dev/null | awk -v M="$VID_TEST_PATHMAX" 'length($0) > M { print; exit }')
[ -z "$f" ] || { echo "error: unable to create file $f: Filename too long" >&2; exit 128; }
exit 0
SG
chmod +x "$T/sbin/git"
DEEP=deep/aaaaaaaaaaaaaaaaaaaa/bbbbbbbbbbbbbbbbbbbb/cccccccccccccccccccc/dddddddddddddddddddd/eeeeeeeeeeeeeeeeeeee/ffffffffffffffffffff/x.txt
# (a) share-push of a bundle holding a deep path
( . "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T/a" > /dev/null; sh_repo quill-tester/toy-shares true
  mkdir -p ".vid/shares/2026-11-local-toy/records/$(dirname "$DEEP")"; printf 'x\n' > ".vid/shares/2026-11-local-toy/records/$DEEP"
  PATH="$T/sbin:$PATH" VID_TEST_PATHMAX=60 sh checks/github.sh share-push --repo quill-tester/toy-shares --project toy --run 2026-11-local-toy .vid/shares/2026-11-local-toy > "$T/out" 2>&1 ) || fail '(a) share-push of a deep bundle was refused'
grep -q 'pushed to quill-tester/toy-shares' "$T/out" || fail '(a) share-push did not say it pushed'
# (b) connect.sh start on a ticket-mode project with no checks/ committed: the refresh adds ViD's deepest file
LM=$( cd "$CHECKS/.." && find checks -type f | awk '{ if (length($0) > m) m = length($0) } END { print m - 1 }' )
( . "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
  mn_project "$T/b" > /dev/null 2>&1; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
  printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
  gh repo create owner/vid-state --private > /dev/null
  [ -z "$(git config --get core.longpaths || true)" ] || fail '(b) the toy starts with core.longpaths set'
  RC=0; PATH="$T/sbin:$PATH" VID_TEST_PATHMAX=$LM sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || RC=$?
  [ "$RC" = 0 ] && grep -qx 'connect: ready' "$T/out" || fail "(b) the start did not end ready ($RC)"
  grep -q '^connect refresh: ' "$T/out" || fail '(b) the start ran no refresh'
  [ "$(git config --bool --get core.longpaths)" = true ] || fail '(b) the project has no core.longpaths after the start'
  git ls-files checks | awk -v M="$LM" 'length($0) > M { f = 1 } END { exit !f }' || fail "(b) the refresh did not commit ViD's deepest file" ) || exit 1
# (e) state-save of records holding a deep path; (f) state-restore into an existing project whose saved commit adds one
( . "$CHECKS/selftest/fixtures/tw-toy.sh"; tw_toy "$T/e" > /dev/null 2>&1; GS=$CHECKS/github.sh
  sh "$GS" spec-setup > "$T/out" 2>&1 || fail '(e) spec-setup failed'
  mkdir -p ".vid/decide/$(dirname "$DEEP")"; printf 'x\n' > ".vid/decide/$DEEP"
  PATH="$T/sbin:$PATH" VID_TEST_PATHMAX=60 sh "$GS" state-save > "$T/out" 2>&1 || fail '(e) the records save of a deep record was refused'
  U=$(gh repo view owner/code-spec --json url --jq .url); git init -q "$T/chk"; git -C "$T/chk" fetch -q "$U" refs/heads/vid-state/records
  git -C "$T/chk" ls-tree -r --name-only FETCH_HEAD | grep -qxF "decide/$DEEP" || fail '(e) the saved records do not hold the deep record: the save dropped it'
  cp .vid/state-at "$T/at0"; H0=$(git rev-parse HEAD)
  mkdir -p "$(dirname "$DEEP")"; printf 'x\n' > "$DEEP"; git add -A -- deep; git -c core.hooksPath=/dev/null commit -qm 'a deep file'
  sh "$GS" state-save > "$T/out" 2>&1 || fail '(f) the second save failed'
  git reset -q --hard "$H0"; cp "$T/at0" .vid/state-at; git config --unset core.longpaths 2> /dev/null || :
  PATH="$T/sbin:$PATH" VID_TEST_PATHMAX=60 sh "$GS" state-restore > "$T/out" 2>&1 || fail '(f) a restore into the project, its saved commit adding a deep path, was refused'
  [ -f "$DEEP" ] || fail '(f) the restore did not bring the deep file' ) || exit 1
# (c) every clone of checks/ carries the setting, so a new clone without it fails here
B=$(grep -n 'git clone' "$CHECKS"/*.sh | grep -v 'core.longpaths=true' | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' | grep -v 'git clone it' || true)
[ -z "$B" ] || fail "(c) a git clone without -c core.longpaths=true: $B"
# (d) vid-init's step 6
K=$CHECKS/../skills/vid-init/SKILL.md
if [ -f "$K" ]; then awk '/^## 6\. / { on = 1; next } on && /^## 6b\. / { exit } on' "$K" | tr '\n' ' ' | grep -qF 'git config core.longpaths true' || fail "(d) vid-init's step 6 does not set core.longpaths"; fi
echo 'git-longpaths: ok'
