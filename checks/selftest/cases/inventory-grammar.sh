#!/bin/sh
# Purpose: selftest case — an inventory grammar line the court does not know (0.26.10.28.1, 9.1 R5, F2). The court,
# inventory.sh with no flag, refuses `grammar: 0.9.4`, `grammar: 0.9.3 # x` and a bare `grammar:` in one line, R5's,
# exit 1; it reads a block with no grammar line, `grammar: 0.9.2` and `grammar: 0.9.3` as before (the oldest reading
# without a line: prose deferrals pass and no par line; with either known line, classed deferrals pass with the par
# line and prose ones are refused); the flags are unchanged (--report on an unknown line still reports). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "inventory-grammar: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p app tests/invariants; printf '```vid-placement\napp/\n```\n' > CLAUDE.md; printf 'x\n' > tests/invariants/a.sh
inv() { # <grammar line or -> <deferral of ROW-002> <deferral of ROW-003>
  { printf '# inv\n```vid-inventory\n'; [ "$1" = - ] || printf '%s\n' "$1"
    printf 'ROW-001 | surface | / | anonymous | n/a | home renders | REQ-001 | tests/invariants/a.sh\n'
    printf 'ROW-002 | surface | /b | anonymous | n/a | b renders | REQ-001 | %s\n' "$2"
    printf 'ROW-003 | surface | /c | anonymous | n/a | c renders | REQ-001 | %s\n```\n' "$3"; } > INVENTORY.md; }
LEGAL1='owed: golden-set — the golden set is not yet ratified'; LEGAL2='owed: owner-decision — OQ-1 pending'
PROSE1='owed: golden set not ratified'; PROSE2='owed: pending owner decision OQ-n'
for g in 'grammar: 0.9.4' 'grammar: 0.9.3 # x' 'grammar:'; do
  inv "$g" "$LEGAL1" "$LEGAL2"
  sh "$CHECKS/inventory.sh" > "$T/out" 2>&1 && fail "'$g' passed the court"
  [ "$(grep -v '^note: ' "$T/out")" = "ViD inventory: refused — '$g' is no inventory grammar: the known ones are 0.9.2 and 0.9.3 (the newest)." ] || fail "'$g': not R5's line alone"
  sh "$CHECKS/inventory.sh" --report > "$T/out" 2>&1 || fail "--report refused '$g'"
  ! grep -q 'is no inventory grammar' "$T/out" || fail "--report carries the court's refusal for '$g'"
done
inv - "$PROSE1" "$PROSE2"; sh "$CHECKS/inventory.sh" > "$T/out" 2>&1 || fail 'no grammar line: the oldest reading refused prose deferrals'
! grep -q '^par:' "$T/out" || fail 'no grammar line: a par line'
for g in 'grammar: 0.9.2' 'grammar: 0.9.3'; do
  inv "$g" "$LEGAL1" "$LEGAL2"; sh "$CHECKS/inventory.sh" > "$T/out" 2>&1 || fail "'$g' with classed deferrals refused"
  grep -q '^par: rows=3 materialised=1 legitimate=2 .* holds' "$T/out" || fail "'$g': no holding par line"
  inv "$g" "$PROSE1" "$PROSE2"; sh "$CHECKS/inventory.sh" > "$T/out" 2>&1 && fail "'$g' with prose deferrals passed"
  [ "$(grep -c 'unclassed deferral' "$T/out")" -eq 2 ] || fail "'$g': not two unclassed deferrals"
done
exit 0
