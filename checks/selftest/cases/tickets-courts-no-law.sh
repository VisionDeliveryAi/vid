#!/bin/sh
# Purpose: selftest case — FB-1 A1: placement.sh and design-cite.sh read ticket mode as inventory.sh does (RUN-STATE's
# `mode: tickets`). A ticket-mode spec repository holds no app source and no CLAUDE.md: with a new file staged and a design pack
# whose marker no code cites, placement passes before its CLAUDE.md test, and design-cite reads no CLAUDE.md and keeps the
# marker's pending report, an extractor present or not. Outside ticket mode both still fail closed on the missing CLAUDE.md.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "tickets-courts-no-law: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"; git init -q
mkdir -p .vid design/screens app; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf '<!-- @screen P01 state=default -->\n<p>the toy page</p>\n' > design/screens/p01.html
printf '# Purpose: a staged file no placement map names\n' > app/main.py; git add app/main.py
c() { RC=0; sh "$CHECKS/$1" > "$T/out" 2>&1 || RC=$?; }
c placement.sh; [ "$RC" = 0 ] || fail "ticket mode, no CLAUDE.md: placement exited $RC"
! grep -q 'CLAUDE.md' "$T/out" || fail 'ticket mode: placement read CLAUDE.md'
c design-cite.sh; [ "$RC" = 0 ] || fail "ticket mode, no CLAUDE.md: design-cite exited $RC"
! grep -q 'CLAUDE.md' "$T/out" || fail 'ticket mode: design-cite read CLAUDE.md'
grep -q '^PEND marker P01/default ' "$T/out" || fail 'ticket mode: the uncited marker has no pending report'
mkdir -p checks/extractors; printf '#!/bin/sh\necho population 0\n' > checks/extractors/invariant.toy.sh
c design-cite.sh; [ "$RC" = 0 ] && grep -q '^PEND marker P01/default ' "$T/out" || fail "ticket mode, an extractor present: the marker lost its pending report ($RC)"
rm -rf checks
# outside ticket mode: as before
printf 'plan: required\nrun: waiting\n' > .vid/RUN-STATE.md
c placement.sh; [ "$RC" != 0 ] && grep -q 'CLAUDE.md missing — failing closed' "$T/out" || fail "outside ticket mode, no CLAUDE.md: placement did not fail closed ($RC)"
c design-cite.sh; [ "$RC" != 0 ] && grep -q 'CLAUDE.md missing — failing closed' "$T/out" || fail "outside ticket mode, no CLAUDE.md: design-cite did not fail closed ($RC)"
echo 'tickets-courts-no-law: ok'
