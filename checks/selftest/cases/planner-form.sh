#!/bin/sh
# Purpose: selftest case — the form of what PL writes, P1 (v0.26.10.12.2.1 R1). On
# the planner's toy (fixtures/planner-toy.sh) the good plan gives no flag; each is flagged, in a fresh copy: a PLAN.md
# line of no form (a PL- row among them); a class line for no row, for a transition, written twice or with neither
# moved: nor limit:; a step without its name; an `origin: plan` row of no kind and form ViD adds — a hostility row
# protecting an item that is not T0 or not its own, an origin naming no pilot item, a ROW not paid at a deploy gate, a
# rule no standing line names, a difference or an exception; a hostility row with no disable: or with a test path, a
# rule whose census is an extractor path; a repeated id, which never overwrites the first; and, inside a repository, a change to INVENTORY.md since
# HEAD outside its `origin: plan` rows, or an inventory not committed. A change to an `origin: plan` row alone is not
# flagged. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-form: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
fresh; pt_check
[ "$PT_RC" -eq 0 ] && grep -q '^planner: clean — 35 rows, 5 steps$' "$T/out" || fail 'the good plan is flagged'
# PLAN.md's lines
fresh; pt_after 'standing work' 'PL-1 | INV-002 | promise: a promise | fail-if: a fail-if | marks: protection | why: a why'; pt_check; [ "$PT_RC" -eq 1 ] || fail 'a flag did not exit 1'
pt_has 'form "PL-1 | INV-002 | promise: a promise | fa" — a line of the rows block that is no class line or standing line'
fresh; pt_after 'standing work' 'the rows of the plan'; pt_check; pt_has 'form "the rows of the plan" — a line of the rows block'
fresh; pt_after 'standing work' 'ROW-099 | limit: A-005'; pt_check; pt_has 'class ROW-099 — a class line for no row of the inventory'
fresh; pt_after 'standing work' 'ROW-004-T2 | limit: A-005'; pt_check; pt_has 'class ROW-004-T2 — a class line for no row of the inventory'
fresh; pt_after 'standing work' 'ROW-012 | limit: A-005'; pt_after 'standing work' 'ROW-012 | limit: A-005'; pt_check; pt_has 'form ROW-012 — the id is used twice'
fresh; pt_after 'standing work' 'ROW-012 | note: A-005'; pt_check; pt_has 'form ROW-012 — a class line with no moved: and no limit:'
fresh; pt_set 'step S02' 'step S02 | modules: ingest digest | builds-on: S01 | rows: ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005 | lane: devagent'; pt_check; pt_has 'form S02 — no name:'
# the rows ViD appends: §3's kinds and forms only
H='| owed: spec-only — ticket | origin: plan'
fresh; pt_set HOS-005 "hostility | HOS-005 | Save an eleventh search | protects: REQ-006 | disable: the guard that protects REQ-006 $H REQ-006"; pt_check
pt_has 'form HOS-005 — an origin: plan hostility row protects its own item, one must-never-happen item, alone'
fresh; pt_set HOS-005 "hostility | HOS-005 | Send an address out | protects: ROW-013 | disable: the guard $H INV-002"; pt_check; pt_has 'form HOS-005 — an origin: plan hostility row protects its own item'
fresh; pt_set RULE-004 "rule | RULE-004 | Every field is acted on | sites: every field | 1 $H REQ-099"; pt_check; pt_has 'form RULE-004 — origin: plan names REQ-099, no effective pilot'
fresh; pt_set 'standing fields' 'standing fields | none: no fields'; pt_check; pt_has 'form RULE-004 — an origin: plan rule no standing line names'
fresh; pt_after HOS-005 "ROW-021 | behavior | REQ-005 | n/a | n/a | A saved search is kept. Fails if it is lost. | REQ-005 $H REQ-005"; pt_check; pt_has 'form ROW-021 — an origin: plan ROW is paid at a deploy gate'
fresh; pt_set DIF-003 "difference | DIF-003 | mail provider | a fake | the real one | its contract | origin: plan REQ-002"; pt_check; pt_has 'form DIF-003 — an origin: plan row of no kind ViD adds'
fresh; pt_set EXC-001 "exception | EXC-001 | the confirmation email | RULE-001 | a reply | origin: plan REQ-012"; pt_check; pt_has 'form EXC-001 — an origin: plan row of no kind ViD adds'
fresh; pt_set HOS-005 "hostility | HOS-005 | Send an address out; expect none sent | protects: INV-002 $H INV-002"; pt_check; pt_has 'form HOS-005 — an origin: plan hostility row with no disable:'
fresh; pt_set HOS-005 "hostility | HOS-005 | Send an address out; expect none sent | protects: INV-002 | disable: the guard that protects INV-002 | tests/invariants/test_addr.py | origin: plan INV-002"; pt_check
pt_has 'form HOS-005 — an origin: plan row whose test field is not owed: spec-only — ticket'
fresh; pt_set RULE-004 "rule | RULE-004 | Every field is acted on | checks/extractors/invariant.fields.sh | 1 $H REQ-005"; pt_check; pt_has 'form RULE-004 — an origin: plan rule with no census of places in words'
fresh; pt_after HOS-005 "ROW-021 | behavior | REQ-005 | n/a | n/a | Kept data survives. Fails if a search is lost. | REQ-005 | owed: paid by /vid deploy gate 1 — the rehearsal | origin: plan REQ-005"; pt_set 'standing rehearsal' 'standing rehearsal | ROW-021'
pt_rs 's/^\(step S04 .*\) RULE-004 /\1 RULE-004 ROW-021 /'; pt_after 'step S05' 'needs ROW-021 | -'; pt_check; [ "$PT_RC" -eq 0 ] || fail 'a well-formed appended rehearsal row is flagged'
fresh; pt_set HOS-005 "hostility | HOS-005 | Send an address out; expect none sent | protects: INV-002 | disable: $H INV-002"; pt_check; pt_has 'form HOS-005 — an origin: plan hostility row with no disable:'
fresh; pt_set HOS-005 "hostility | HOS-005 | Send an address out; expect none sent | protects: INV-002 | disable: the guard that protects INV-002 | owed: spec-only — ticket | proved-red: 1a2b3c4 | origin: plan INV-002"; pt_check
pt_has "form HOS-005 — an origin: plan row with 8 fields, not its form's 7"
fresh; pt_after EXC-001 'exception | EXC-001 | the welcome email | RULE-001 | a one-off reply'; pt_check; pt_has 'form EXC-001 — the id is used twice'
# a repeated id: a duplicate line, or an appended row numbered like a ratified one, never overwrites the first
fresh; pt_after ROW-019 'ROW-001 | behavior | REQ-001 | anonymous | n/a | Another promise. | REQ-001 | owed: spec-only — first stage'; pt_check; pt_has 'form ROW-001 — the id is used twice'
sh "$CHECKS/planner.sh" rows | awk -F'\t' '$1 == "ROW-001" { print $8 }' | grep -qx 'Each saved search gets one digest a day, holding only jobs it has not sent before.' || fail 'the duplicate overwrote the first ROW-001'
fresh; pt_set HOS-005 "hostility | HOS-001 | Send an address out | protects: INV-002 | disable: the guard that protects INV-002 $H INV-002"; pt_rs 's/ HOS-005 / HOS-001 /'; pt_check; pt_has 'form HOS-001 — the id is used twice'
# inside a repository: INVENTORY.md changes since HEAD only in its origin: plan rows
G() { git -c user.email=t@t -c user.name=t "$@" > /dev/null 2>&1; }
fresh; git init -q . && G add -A && G commit -m toy; pt_check; [ "$PT_RC" -eq 0 ] || fail 'the committed toy is flagged'
pt_set HOS-005 "hostility | HOS-005 | Have the product send an address to a feed source; expect none sent | protects: INV-002 | disable: the guard that protects INV-002 $H INV-002"; pt_check; [ "$PT_RC" -eq 0 ] || fail 'an origin: plan row amended is flagged'
pt_del RULE-005; pt_set 'standing work' 'standing work | none: nothing is queued'; pt_rs 's/ RULE-005 / /'; pt_check; [ "$PT_RC" -eq 0 ] || fail 'an origin: plan row removed is flagged'
pt_set ROW-019 'ROW-019 | behavior | REQ-012 | anonymous | n/a | Every footer gives an address. | REQ-012 | owed: spec-only — first stage | origin: REQ-012'; pt_check
pt_has 'inventory INVENTORY.md — changed since HEAD outside its origin: plan rows'
fresh; git init -q .; pt_check; pt_has 'inventory INVENTORY.md — not committed'
exit 0
