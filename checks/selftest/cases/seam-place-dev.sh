#!/bin/sh
# Purpose: selftest case — a seam row's `place: dev` at the inventory court, and develop unchanged by it (FB-4 A2). `place: dev`
# with `credentials: held` passes; with not-yet, never or none it is a gap naming the row, refused by default and under --strict,
# in a block with a grammar line and in one without; a `place:` of any other word is a gap too. With the field and without it,
# an owed seam's client line is refused alike by checks/seams.sh, a probed one's passes alike, and checks/inventory.sh prints
# and exits the same in every mode. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "seam-place-dev: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/app"; cd "$T/p"; git init -q; printf '```vid-placement\napp/\n```\n' > CLAUDE.md
# inv <grammar line> <credentials> <probe> <place field>
inv() { printf '# toy\n```vid-inventory\n%s\nseam | SEAM-002 | mailer | transactional mail | chosen: D-007 | credentials: %s | probe: %s | evidence: owed | quirks: none yet%s | match: mailerlib\n```\n' "$1" "$2" "$3" "$4" > INVENTORY.md; }
run() { RC=0; sh "$CHECKS/inventory.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
P='probed(2026-11-02)'
for gr in 'grammar: 0.9.2' 'grammar: 0.9.3' ''; do
  inv "$gr" held "$P" ' | place: dev'; run; [ "$RC" = 0 ] || fail "place: dev with credentials held was refused (${gr:-no grammar})"
  for c in not-yet never; do inv "$gr" "$c" 'unreachable-risk(credentials not-yet)' ' | place: dev'; run; [ "$RC" = 1 ] || fail "place: dev with credentials $c passed (${gr:-no grammar})"
    grep -q '^GAP  SEAM-002 (mailer) — place: dev needs credentials: held' "$T/out" || fail 'the gap does not name the row and why'
    run --strict; [ "$RC" = 1 ] || fail "--strict passed place: dev with credentials $c"; done
  inv "$gr" held "$P" ' | place: staging'; run; [ "$RC" = 1 ] && grep -q '^GAP  SEAM-002 (mailer) — place: staging' "$T/out" || fail "place: staging passed (${gr:-no grammar})"
done
# develop: the same with the field and without it
printf '# Purpose: the mail client\nimport mailerlib\n' > app/mail.py
for pr in owed "$P"; do for f in '' ' | place: dev'; do v=$([ -z "$f" ] && echo without || echo with)
  inv 'grammar: 0.9.3' held "$pr" "$f"; git add -A
  for m in '' --report --strict; do RC=0; sh "$CHECKS/inventory.sh" $m > "$T/$v$m" 2>&1 || RC=$?; echo "exit $RC" >> "$T/$v$m"; done
  RC=0; sh "$CHECKS/seams.sh" > "$T/$v.seams" 2>&1 || RC=$?; echo "exit $RC" >> "$T/$v.seams"; done
  for m in '' --report --strict .seams; do cmp -s "$T/with$m" "$T/without$m" || { diff "$T/without$m" "$T/with$m" > "$T/out" || :; fail "${m:-inventory.sh} differs with the field (probe $pr)"; }; done
  if [ "$pr" = owed ]; then grep -q 'SEAM-002' "$T/with.seams" && grep -qx 'exit 1' "$T/with.seams" || fail 'the owed seam'"'"'s client line passed'; else grep -qx 'exit 0' "$T/with.seams" || fail 'the probed seam'"'"'s client line was refused'; fi
done
exit 0
