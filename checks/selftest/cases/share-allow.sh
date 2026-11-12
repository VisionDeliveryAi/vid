#!/bin/sh
# Purpose: selftest case — the share's calls on github.sh's allow-list, each as narrow as the spec repository's (0.26.10.28.7, R6).
# ghc, read out of github.sh with its login-form helper and run against a gh that only logs, refuses: gh api users/<name> with
# -X, with a further path after the name, for a name not in GitHub's login form, or for any account but the one named to
# invite; gh repo create of any repository but the share repository, or without --private, or with more after it, or outside
# share-create; a membership
# read of another account; a collaborator call but a read or -X PUT, or on another repository; the share's calls outside a share
# subcommand, and any other gh api path inside one; any argument but the share's exact forms (--method, an attached -X, a field
# but the invitation's permission=pull, --paginate but on the invitations). Each refusal calls no gh. The share's own calls pass. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-allow: $*" >&2; exit 1; }
{ echo 'gref() { echo "refused: $*" >&2; exit 1; }'; sed -n '/^lform() {/p' "$CHECKS/github.sh"; sed -n '/^ghc() {/,/^}/p' "$CHECKS/github.sh"; } > "$T/ghc.sh"
grep -q '^ghc() {' "$T/ghc.sh" && grep -q '^lform() {' "$T/ghc.sh" || fail 'ghc or lform could not be read from github.sh'
mkdir "$T/bin"; printf '#!/bin/sh\necho "gh $*" >> "%s/log"\n' "$T" > "$T/bin/gh"; chmod +x "$T/bin/gh"; PATH="$T/bin:$PATH"
call() { ( . "$T/ghc.sh"; REPO=owner/code; SHARE=${SH-yes}; SCREATE=${SC-yes}; SREPO=quill-tester/vid-shares; LOGIN=quill-tester; SOWN=quill-tester; WHO=${W-bramble-reader}; ghc "$@" ) > /dev/null 2>&1; }
no() { : > "$T/log"; if call "$@"; then fail "allowed: gh $*"; fi; [ ! -s "$T/log" ] || fail "a refused call reached gh: gh $*"; }
ok() { : > "$T/log"; call "$@" || fail "refused: gh $*"; [ -s "$T/log" ] || fail "an allowed call did not reach gh: gh $*"; }
ok api user --jq .login; ok api users/bramble-reader --jq .type; ok api orgs/quill-tester/memberships/quill-tester --jq .role
ok api repos/quill-tester/vid-shares/collaborators/bramble-reader; ok api -X PUT repos/quill-tester/vid-shares/collaborators/bramble-reader -f permission=pull
ok api repos/quill-tester/vid-shares/invitations --jq '.[].invitee.login'; ok repo create quill-tester/vid-shares --private
# users/<name>: a read of the one named account, in login form, nothing after it
no api -X PUT users/bramble-reader; no api -X DELETE users/bramble-reader; no api users/bramble-reader/repos; no api users/ferngrove
W='bramble.reader' no api users/bramble.reader; W='-bramble' no api users/-bramble; W='bram--ble' no api users/bram--ble; W='' no api users/
# repo create: the share repository alone, --private, nothing more
no repo create quill-tester/other --private; no repo create quill-tester/vid-shares; no repo create quill-tester/vid-shares --public
no repo create quill-tester/vid-shares --private --public; SC='' no repo create quill-tester/vid-shares --private
# the other share calls, each tied to its one target
no api orgs/quill-tester/memberships/ferngrove; no api -X PUT orgs/quill-tester/memberships/quill-tester
no api -X DELETE repos/quill-tester/vid-shares/collaborators/bramble-reader; no api repos/ferngrove/shared/collaborators/bramble-reader
no api repos/quill-tester/vid-shares/collaborators/ferngrove; no api -X POST repos/quill-tester/vid-shares/invitations; no api repos/ferngrove/shared/invitations
no api repos/quill-tester/vid-shares/contents; no api repos/owner/code/milestones
# only the share's exact argument forms: no --method, no attached -X, no field but the invitation's permission=pull, --paginate on the invitations alone
no api --method DELETE repos/quill-tester/vid-shares/collaborators/bramble-reader; no api -XDELETE repos/quill-tester/vid-shares/collaborators/bramble-reader
no api -f name=changed user; no api -F name=changed user; no api --field name=x user; no api --raw-field name=x user; no api --input /dev/null user
no api --method PUT users/bramble-reader; no api --method=DELETE repos/quill-tester/vid-shares/collaborators/bramble-reader; no api users/bramble-reader -f name=x
no api -X PUT repos/quill-tester/vid-shares/collaborators/bramble-reader -f permission=admin; no api repos/quill-tester/vid-shares/collaborators/bramble-reader -f permission=pull
no api user --paginate; no api user users/bramble-reader; ok api repos/quill-tester/vid-shares/invitations --paginate --jq '.[].invitee.login'
# outside a share subcommand, none of them
SH='' no api user; SH='' no api users/bramble-reader; SH='' no api repos/quill-tester/vid-shares/collaborators/bramble-reader
SH='' no repo create quill-tester/vid-shares --private
# the switches never come from the environment: an exported SHARE or SCREATE does not reach ghc in github.sh
grep -q "^REPO=''; SHARE=''; SCREATE=''" "$CHECKS/github.sh" || fail 'github.sh does not clear SHARE and SCREATE at its start'
echo 'share-allow: ok'
