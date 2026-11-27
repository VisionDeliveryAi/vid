#!/bin/sh
# Purpose: selftest case — one failed gh auth status stops nothing (FIX-BATCH-T2 §9, OW-2). The fakes' auth-blip makes the next n
# `gh auth status` calls fail as a network blip. On the share's toy: a blip once, then share-push (whose first act is auth())
# pushes, and share-login prints the login; two blips, the third try passing: share-login passes; a blip three times:
# share-push refused with the last try's words after exactly three tries; logged out:
# refused at once, with one try. On the GitHub manual toy: `access` with a blip once reads gh as signed in. VID_NET_WAIT=0, so
# the case does not wait. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "github-auth-retry: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
VID_NET_WAIT=0; export VID_NET_WAIT
( . "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T/s" > /dev/null; sh_repo quill-tester/toy-shares true; GS=checks/github.sh; BF=.vid/shares/2026-11-local-toy
  echo 1 > "$SHAREGH/auth-blip"; sh "$GS" share-push --repo quill-tester/toy-shares --project toy --run 2026-11-local-toy "$BF" > "$T/out" 2>&1 || fail 'share-push was refused for one failed gh auth status'
  echo 1 > "$SHAREGH/auth-blip"; sh "$GS" share-login > "$T/out" 2>&1 || fail 'share-login failed for one failed gh auth status'
  grep -qx quill-tester "$T/out" || fail 'share-login did not print the login after a blip'
  echo 2 > "$SHAREGH/auth-blip"; sh "$GS" share-login > "$T/out" 2>&1 || fail 'share-login failed for two failed gh auth status, the third passing'
  echo 3 > "$SHAREGH/auth-blip"; A0=$(grep -c 'auth status' "$SHAREGH/log" || true); if sh "$GS" share-push --repo quill-tester/toy-shares --project toy --run 2026-11-local-toy2 "$BF" > "$T/out" 2>&1; then fail 'share-push passed three failed gh auth status'; fi
  grep -q 'error connecting to api.github.com' "$T/out" || fail 'the refusal does not show the last try'"'"'s words'
  A1=$(grep -c 'auth status' "$SHAREGH/log" || true); [ $((A1 - A0)) = 3 ] || fail "three failures were tried $((A1 - A0)) times, not 3"
  rm -f "$SHAREGH/auth-blip"; : > "$SHAREGH/auth-fail"; L0=$(grep -c 'auth status' "$SHAREGH/log" || true)
  if sh "$GS" share-login > "$T/out" 2>&1; then fail 'share-login passed while logged out'; fi
  L1=$(grep -c 'auth status' "$SHAREGH/log" || true); [ $((L1 - L0)) -le 1 ] || fail "a logged-out answer was tried $((L1 - L0)) times" ) || exit 1
( . "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
  mn_project "$T/m" > /dev/null 2>&1; echo 1 > "$FAKEGH/auth-blip"
  sh "$CHECKS/github.sh" access > "$T/out" 2>&1 || :; grep -qx 'access gh — signed in' "$T/out" || fail "access read one blip as not signed in: $(head -n 1 "$T/out")" ) || exit 1
echo 'github-auth-retry: ok'
