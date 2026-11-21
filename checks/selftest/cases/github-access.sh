#!/bin/sh
# Purpose: selftest case — the setup's access check, read only (v0.26.10.12.3.1 R3). With
# stage 2's fake gh (fixtures/tickets.sh gh_fake, its viewerPermission answer) and .vid/tw/settings naming owner/code
# and owner/code-spec (private): signed in, both reached, `access: ok`; the permission as the fake's perm file holds
# it; the spec repository public (not ready, `access: 1 of 3 not ready`); a spec repository and a code repository not
# reached, in gh's words; a key left out (not set yet); not signed in (it stops, `access: 1 of 1 not ready`); with
# layout: one, the spec repository's line as with two repositories (GM-4 J5: the private spec repository stays in both
# layouts): not set yet while spec-repo: is left out, reached once it is set. Exit 0 each time, 2 on a usage error; the fake's log holds only gh auth status
# and gh repo view (the fake gh adds its exit code to its own words). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "github-access: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/tickets.sh"
gh_fake; mkdir -p "$T/v/.vid/tw" "$T/gh/repos/owner%code-spec"; echo true > "$T/gh/repos/owner%code-spec/private"; cd "$T/v"
set_() { printf '%b' "$1" > .vid/tw/settings; }
acc() { RC=0; sh "$CHECKS/github.sh" access > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "access exited $RC"; }
is() { [ "$(cat "$T/out")" = "$(printf '%b' "$1")" ] || fail "not as expected: $2"; }
G='access gh — signed in\n'; R='access repo owner/code — reached, ADMIN, private\n'
set_ 'repo: owner/code\nspec-repo: owner/code-spec\nlabels-prefix:\n'
acc; is "${G}${R}access spec-repo owner/code-spec — reached, ADMIN, private\naccess: ok" 'both reached'
echo WRITE > "$T/gh/perm"; echo MAINTAIN > "$T/gh/repos/owner%code-spec/perm"
acc; is "${G}access repo owner/code — reached, WRITE, private\naccess spec-repo owner/code-spec — reached, MAINTAIN, private\naccess: ok" 'the permissions'
rm "$T/gh/perm" "$T/gh/repos/owner%code-spec/perm"; echo false > "$T/gh/repos/owner%code-spec/private"
acc; is "${G}${R}access spec-repo owner/code-spec — public: spec-setup refuses it\naccess: 1 of 3 not ready" 'a public spec repository'
N="Could not resolve to a Repository with the name"
set_ 'repo: owner/code\nspec-repo: owner/other-spec\n'
acc; is "${G}${R}access spec-repo owner/other-spec — not reached: fake gh: $N 'owner/other-spec'. 1; spec-setup makes it if it does not exist yet\naccess: 1 of 3 not ready" 'a spec repository not reached'
set_ 'repo: owner/none\nspec-repo: owner/other-spec\n'
acc; grep -qx "access repo owner/none — not reached: fake gh: $N 'owner/none'. 1" "$T/out" && grep -qx 'access: 2 of 3 not ready' "$T/out" || fail 'a code repository not reached'
set_ 'repo: owner/code\n'; acc; is "${G}${R}access spec-repo — not set yet\naccess: 1 of 3 not ready" 'a spec-repo: left out'
set_ ''; acc; is "${G}access repo — not set yet\naccess spec-repo — not set yet\naccess: 2 of 3 not ready" 'no settings keys'
set_ 'layout: one\nrepo: owner/code\n'; acc; is "${G}${R}access spec-repo — not set yet\naccess: 1 of 3 not ready" 'one repository, no spec-repo:'
echo true > "$T/gh/repos/owner%code-spec/private"
set_ 'layout: one\nrepo: owner/code\nspec-repo: owner/code-spec\n'; acc; is "${G}${R}access spec-repo owner/code-spec — reached, ADMIN, private\naccess: ok" 'one repository, the spec repository reached'
touch "$T/gh/auth-fail"; acc; is 'access gh — not signed in: You are not logged into any GitHub hosts. To log in, run: gh auth login\naccess: 1 of 1 not ready' 'not signed in'
rm "$T/gh/auth-fail"; RC=0; sh "$CHECKS/github.sh" access extra > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "a usage error exited $RC"
[ -z "$(sed -e '/^gh auth status$/d' -e '/^gh repo view /d' "$T/gh/log")" ] || fail "a call but auth status and repo view: $(sed -e '/^gh auth status$/d' -e '/^gh repo view /d' "$T/gh/log" | head -n 1)"
grep -q '^gh repo view owner/code --json viewerPermission' "$T/gh/log" || fail 'the permission is not asked'
exit 0
