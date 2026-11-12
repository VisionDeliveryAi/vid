#!/bin/sh
# Purpose: selftest case — the share's invitation (0.26.10.28.7, R6), on the share's toy and its fake gh, made-up names alone.
# share-invite refuses without either of its two flags, with no call after gh auth status; a name not in GitHub's login form is
# refused; on a personal account's repository an account that reads as an organisation is refused, with no invitation call, and
# a person is invited (GitHub's only role there, write); an invitation pending (on any page), or a collaborator already there, is not sent
# again; on the user's own organisation's repository the person is invited with the Read role (permission=pull). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-invite: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T"; GS=checks/github.sh; R=quill-tester/vid-shares
sh_repo "$R" true; D=$(sh_dir "$R")
no() { if sh "$GS" "$@" > "$T/out" 2>&1; then fail "not refused: $*"; fi; }
puts() { grep -c "PUT repos/$1/collaborators/" "$SHAREGH/log" || true; }
# the two flags
for f in '--shown-write-words' '--second-yes' ''; do sh_mark
  if [ -n "$f" ]; then no share-invite --repo "$R" --who bramble-reader "$f"; else no share-invite --repo "$R" --who bramble-reader; fi
  [ "$(sh_calls | paste -sd '|' -)" = 'gh auth status' ] || fail "an invitation missing a flag called more than gh auth status: $(sh_calls | paste -sd '|' -)"; done
no share-invite --repo "$R" --who 'bramble/reader' --shown-write-words --second-yes; no share-invite --repo "$R" --who '-bramble' --shown-write-words --second-yes
# an organisation, on a personal account's repository
no share-invite --repo "$R" --who quill-labs --shown-write-words --second-yes
grep -q 'invites people only, not an organisation' "$T/out" && [ "$(puts "$R")" = 0 ] || fail 'an organisation was invited to a personal account'"'"'s repository'
# a person: invited once
sh "$GS" share-invite --repo "$R" --who bramble-reader --shown-write-words --second-yes > "$T/out" 2>&1 || fail 'a person was not invited'
[ -f "$D/invitations/bramble-reader" ] && [ "$(puts "$R")" = 1 ] && grep -q 'write access' "$T/out" || fail 'the invitation was not sent once, or its access not said'
grep -q 'Settings, then Collaborators' "$T/out" || fail 'how to take the access away is not said'
sh "$GS" share-invite --repo "$R" --who bramble-reader --shown-write-words --second-yes > "$T/out" 2>&1 && [ "$(puts "$R")" = 1 ] && grep -q 'pending: not invited again' "$T/out" || fail 'a pending invitation was sent again'
mkdir -p "$D/invitations-page2"; : > "$D/invitations-page2/ferngrove"; sh "$GS" share-invite --repo "$R" --who ferngrove --shown-write-words --second-yes > "$T/out" 2>&1 && [ "$(puts "$R")" = 1 ] || fail 'an invitation pending on a later page was sent again'
rm "$D/invitations-page2/ferngrove"; : > "$D/collab/ferngrove"; sh "$GS" share-invite --repo "$R" --who ferngrove --shown-write-words --second-yes > "$T/out" 2>&1 && [ "$(puts "$R")" = 1 ] || fail 'a collaborator was invited again'
# the user's own organisation: the Read role
sh_repo quill-labs/runs true true
sh "$GS" share-invite --repo quill-labs/runs --who bramble-reader --shown-write-words --second-yes > "$T/out" 2>&1 || fail 'the organisation invitation failed'
grep -qx 'gh api -X PUT repos/quill-labs/runs/collaborators/bramble-reader -f permission=pull' "$SHAREGH/log" && grep -q 'read access' "$T/out" || fail 'the organisation repository did not ask the Read role'
echo 'share-invite: ok'
