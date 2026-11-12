#!/bin/sh
# Purpose: selftest case — no GitHub login, no send (0.26.10.28.7, R6), on the share's toy and its fake gh. With gh auth status
# failing, share-login says the bundle stays a file you can send by hand and exits 1, and share-login, share-create, share-push
# and share-invite each make no call after gh auth status, and write nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-nologin: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T"; GS=checks/github.sh; R=quill-tester/vid-shares; touch "$SHAREGH/auth-fail"
if sh "$GS" share-login > "$T/out" 2>&1; then fail 'share-login passed with no login'; fi
grep -q 'stays a file you can send by hand' "$T/out" || fail 'the file is not offered'
for c in 'share-login' "share-create --repo $R" "share-push --repo $R --project toy --run r1 .vid/shares/2026-11-local-toy" "share-invite --repo $R --who bramble-reader --shown-write-words --second-yes"; do
  sh_mark; IFS=' '; set -- $c; IFS='
'; if sh "$GS" "$@" > "$T/out" 2>&1; then fail "$1 ran with no login"; fi
  [ "$(sh_calls | paste -sd '|' -)" = 'gh auth status' ] || fail "$1 called more than gh auth status: $(sh_calls | paste -sd '|' -)"; done
[ ! -d "$SHAREGH/repos/quill-tester%vid-shares" ] || fail 'a repository was made with no login'
echo 'share-nologin: ok'
