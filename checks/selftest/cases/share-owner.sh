#!/bin/sh
# Purpose: selftest case — the share repository is private and the user's own before every write (0.26.10.28.7, R6), on the
# share's toy and its fake gh, made-up names alone. Refused, writing nothing: a private repository another person owns (one the
# user could push to); one in an organisation the user is not an owner of, at create and at push; a repository that reads
# public, internal (seen by its whole enterprise), or whose read fails, before the push; one that reads private before the push and public before the invitation gets no
# invitation. In an organisation the user owns, the repository is made there and the push goes through. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-owner: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T"; GS=checks/github.sh; BF=.vid/shares/2026-11-local-toy
no() { if sh "$GS" "$@" > "$T/out" 2>&1; then fail "not refused: $*"; fi; }
pushes() { git --git-dir="$(sh_dir "$1")/remote.git" rev-parse -q --verify main > /dev/null 2>&1; }
# another person's private repository, which the user can push to
sh_repo ferngrove/shared true; no share-create --repo ferngrove/shared; grep -q 'not an owner of ferngrove' "$T/out" || fail "another person's repository: $(cat "$T/out")"
no share-push --repo ferngrove/shared --project toy --run r1 "$BF"; ! pushes ferngrove/shared || fail "a push went to another person's repository"
! grep -q 'repo create ferngrove' "$SHAREGH/log" || fail "a repository was made in another person's account"
# an organisation the user is not an owner of
mkdir -p "$SHAREGH/orgs/mossbank"; echo 'active member' > "$SHAREGH/orgs/mossbank/quill-tester"
no share-create --repo mossbank/runs; ! grep -q 'repo create mossbank' "$SHAREGH/log" || fail "a repository was made in an organisation the user does not own"
sh_repo mossbank/runs true true; no share-push --repo mossbank/runs --project toy --run r1 "$BF"; ! pushes mossbank/runs || fail "a push went to an organisation the user does not own"
# public, or a failed read, before the push
sh_repo quill-tester/open false; no share-push --repo quill-tester/open --project toy --run r1 "$BF"; grep -q 'is not private' "$T/out" && ! pushes quill-tester/open || fail 'a public repository was pushed to'
sh_repo quill-tester/flaky true; : > "$(sh_dir quill-tester/flaky)/view-fail"; no share-push --repo quill-tester/flaky --project toy --run r1 "$BF"
grep -q 'counts as not private' "$T/out" && ! pushes quill-tester/flaky || fail 'a repository whose read failed was pushed to'
# an enterprise's internal repository is no private one
sh_repo quill-labs/inside internal true; no share-push --repo quill-labs/inside --project toy --run r1 .vid/shares/2026-11-local-toy; grep -q 'is not private' "$T/out" && ! pushes quill-labs/inside || fail 'an internal repository was pushed to'
no share-create --repo quill-labs/inside; grep -q 'is not private' "$T/out" || fail 'an internal repository was taken by share-create'
# private before the push, public before the invitation: no invitation
sh_repo quill-tester/turns true; sh "$GS" share-push --repo quill-tester/turns --project toy --run r1 "$BF" > "$T/out" 2>&1 || fail 'the push to a private repository failed'
echo false > "$(sh_dir quill-tester/turns)/private"
no share-invite --repo quill-tester/turns --who bramble-reader --shown-write-words --second-yes
! grep -q 'PUT repos/quill-tester/turns' "$SHAREGH/log" && grep -q 'is not private' "$T/out" || fail 'a repository gone public got an invitation'
# an organisation the user owns: made there, private, and the push goes
sh "$GS" share-create --repo quill-labs/runs > "$T/out" 2>&1 || fail "share-create in the user's own organisation failed"
grep -qx 'gh repo create quill-labs/runs --private' "$SHAREGH/log" || fail 'the organisation repository was not made --private'
sh "$GS" share-push --repo quill-labs/runs --project toy --run r1 "$BF" > "$T/out" 2>&1 && pushes quill-labs/runs || fail "the push to the user's own organisation failed"
echo 'share-owner: ok'
