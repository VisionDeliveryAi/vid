#!/bin/sh
# Purpose: selftest case — `checks/inventory.sh cites <id> …` (0.26.10.29.4, phase 3 R2, F12) lists every inventory line
# that depends on an amended id, by the court's own reading (a ROW's derived-from, `protects:`, `origin:`, and an
# exception's or suppression's rule in its census-class field), and follows the chain until nothing new is added.
# `cites REQ-7` prints the ROW derived from REQ-7, the rule whose origin: is REQ-7, the hostility row protecting that
# rule and the exception to that rule, and nothing else: not the lines of REQ-8 or REQ-70, not a line that only says
# REQ-7 in its words. It reads the working INVENTORY.md in a directory that is no git repository. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/p"; cd "$T/p"
GIT_CEILING_DIRECTORIES=$T; export GIT_CEILING_DIRECTORIES
fail() { echo "inventory-cites-follows-chain: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then fail 'the scratch directory is inside a git repository'; fi
R1='ROW-001 | behavior | send | user | n/a | consent off: no mail is sent | REQ-7 | owed: guard-first — the send step'
R2='ROW-002 | behavior | list | user | n/a | the list shows what REQ-7 sends | REQ-8 | owed: guard-first — the list step'
R3='ROW-003 | behavior | export | user | n/a | the export holds ten | REQ-70 | owed: guard-first — the export step'
U1='rule | RULE-001 | every send reads consent | checks/extractors/invariant.consent.sh | 0 | owed: census-armed — the consent extractor | origin: REQ-7'
U2='rule | RULE-002 | every list is bounded | checks/extractors/invariant.bounded.sh | 1 | owed: census-armed — the bounded extractor | origin: REQ-8'
H1='hostility | HOS-001 | send with consent off through the send form | protects: RULE-001 | disable: the consent check | owed: guard-first — the send step'
H2='hostility | HOS-002 | list past the cap through the list page | protects: RULE-002 | disable: the cap | owed: guard-first — the list step'
E1='exception | EXC-001 | the system notice | RULE-001 | the notice is no marketing mail'
E2='exception | EXC-002 | the admin list | RULE-002 | an admin list is short'
S2='suppression | SUP-001 | the feed list | RULE-002 | the extractor cannot see the feed | fix-by: the feed step'
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n```\n' "$R1" "$R2" "$R3" "$U1" "$U2" "$H1" "$H2" "$E1" "$E2" "$S2" > INVENTORY.md
RC=0; sh "$CHECKS/inventory.sh" cites REQ-7 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "cites exited $RC outside a repository"
printf '%s\n' "$R1" "$U1" "$H1" "$E1" > "$T/want"
cmp -s "$T/want" "$T/out" || { echo 'inventory-cites-follows-chain: expected exactly:' >&2; cat "$T/want" >&2; fail 'cites REQ-7 printed another set (above: what it printed)'; }
# two ids at once: the union, each line once
RC=0; sh "$CHECKS/inventory.sh" cites REQ-7 RULE-002 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "cites with two ids exited $RC"
printf '%s\n' "$R1" "$U1" "$H1" "$H2" "$E1" "$E2" "$S2" > "$T/want"
cmp -s "$T/want" "$T/out" || { echo 'inventory-cites-follows-chain: expected exactly:' >&2; cat "$T/want" >&2; fail 'cites REQ-7 RULE-002 printed another set (above: what it printed)'; }
# an id nothing cites: silent, exit 0
RC=0; sh "$CHECKS/inventory.sh" cites REQ-99 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && [ ! -s "$T/out" ] || fail "cites REQ-99 was not silent with exit 0 ($RC)"
# no id: a usage refusal
RC=0; sh "$CHECKS/inventory.sh" cites > "$T/out" 2>&1 || RC=$?
[ "$RC" = 2 ] || fail "cites with no id exited $RC, not 2"
# a CR LF inventory is refused, as every reading refuses it
printf 'x\r\n' >> INVENTORY.md
RC=0; sh "$CHECKS/inventory.sh" cites REQ-7 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] || fail "cites read a CR LF INVENTORY.md (exit $RC)"
echo 'inventory-cites-follows-chain: ok'
