#!/bin/sh
# Purpose: selftest case — every route is read, P9 (v0.26.10.12.2.1 R2). On the planner's toy
# (fixtures/planner-toy.sh, a row of every type), `planner.sh rows` gives every ROW, rule, difference, hostility and
# seam line as a planned row with its id, kind, items, stage, mark and carried fields; an exception naming a rule is
# carried on it; what §2.3 leaves out (a test path, proved-red:, a golden: path as text, an extractor census, a
# suppression, a class-only exception, a seam's evidence path, module: and match:) is absent; each ROW row gives its
# obligation back whole (a journey through its transitions and their separators, ` ; `, `; ` and ` · `); a later-phase
# row has the class later; a difference with no paying step is a record; ViD's appended rows read back like the rest,
# and `rows --added` prints them as written. An unread line and a missing golden set are
# flagged; `rows --short` cuts a promise to 80 characters; `rows` runs with no PLAN.md. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
rows() { sh "$CHECKS/planner.sh" rows "$@" > "$T/rows" 2> "$T/out" || fail 'rows failed'; }
col() { awk -F'\t' -v id="$1" -v c="$2" '$1 == id { print $c }' "$T/rows"; }
is() { [ "$(col "$1" "$2")" = "$3" ] || fail "$1's column $2 is [$(col "$1" "$2")], not [$3]"; }
has() { col "$1" 11 | grep -qF -- "$2" || fail "$1 does not carry: $2"; }
fresh; pt_check; [ "$PT_RC" -eq 0 ] || fail 'the toy is flagged'; rows
# every line a row, by its route: id, kind, mark, stage, items, class
[ "$(grep -v '^#' "$T/rows" | cut -f1 | tr '\n' ' ')" = 'ROW-001 ROW-002 ROW-003 ROW-004 ROW-004-T1 ROW-004-T2 ROW-004-T3 ROW-005 ROW-005-T1 ROW-005-T2 ROW-005-T3 ROW-006 ROW-007 ROW-008 ROW-009 ROW-010 ROW-011 ROW-012 ROW-013 ROW-014 ROW-015 ROW-016 ROW-017 ROW-018 ROW-019 ROW-020 RULE-001 RULE-002 RULE-003 DIF-001 DIF-002 DIF-003 HOS-001 HOS-002 HOS-003 HOS-004 HOS-005 RULE-004 RULE-005 SEAM-001 SEAM-002 ' ] || fail 'the rows are not every inventory line, in order'
for r in ROW-004:journey ROW-005:journey ROW-006:shell ROW-007:reachability ROW-009:owed-rehearsal ROW-010:owed-staging ROW-011:owed-production RULE-003:rule HOS-003:protection DIF-001:owed-staging DIF-002:owed-staging SEAM-001:seam ROW-001: ROW-008: ROW-013: ROW-017:; do is "${r%%:*}" 7 "${r#*:}"; done
is ROW-004-T2 2 tr; is ROW-004-T2 3 ROW-004; is DIF-003 2 record; is DIF-003 6 record
is ROW-003 5 0; is ROW-004 5 0; is ROW-004-T1 5 0; is ROW-017 5 2; is SEAM-002 5 1; is ROW-020 5 later; is ROW-020 6 later; is ROW-010 6 owed
is ROW-003 4 REQ-001; is ROW-004 4 'REQ-001 REQ-002 REQ-005'; is RULE-001 4 REQ-012; is HOS-001 4 INV-001; is HOS-002 4 REQ-002
is HOS-003 4 REQ-006; is HOS-004 4 REQ-012; is DIF-001 4 ''; is HOS-005 4 INV-002; is RULE-004 4 REQ-005; is HOS-005 7 protection; is RULE-005 7 rule
# promise and fail-if, by route
is ROW-015 8 'A saved search keeps its words, its address and its last-digest time through a feed outage.'
is ROW-015 9 'At ingest: fails if a feed outage or re-read loses a saved search or resets its last-digest time.'
is ROW-002 9 'what the promise says is not what is observed'
is HOS-001 8 'Send the same job on both feeds at once; expect exactly one listing'; is HOS-001 9 'attempting this brings about what INV-001 forbids'
is RULE-003 8 'state-machine subscription.status: pending>active active>unsubscribed'
is DIF-002 8 'close run, profile=deployed'; is DIF-003 8 'what a provider does with an address is its contract, not a product promise'
is SEAM-002 8 "scheduled read of the partner's active jobs"; is ROW-005-T2 8 '(process) at the listings · the same job on the second feed · merge · one listing · the job is listed once'
# carried, word for word, under their names
has ROW-003 'kind: surface · subject: S01 · actor: anonymous · marker: S01/saved · derived-from: REQ-001, S01/saved · test: owed: spec-only — first stage · origin: design 2026-08-28 S01/saved'
has ROW-002 'test: owed: prerequisite — the harness holds'; has ROW-012 'test: owed: fixture-source — a 10,000-job'; has ROW-018 'test: owed: owner-decision — OQ-3'
has ROW-010 'paid-at: gate-2 2026-09-01 deploy-log 4'; has ROW-019 'law-changed: A-005 amended'; has ROW-017 'divergence: DIF-001'; has ROW-005 'actor: (process)'
has RULE-001 'census: sites: every digest template :: guarded: those rendering the support footer · tier: 1 · test: owed: census-armed'
has RULE-001 'except: the unsubscribe confirmation email — it is a one-off reply to the subscriber, not a digest (EXC-001)'; has RULE-003 'tier: 0'
has HOS-002 'protects: REQ-002 · disable: skip the unsubscribe check in the digest run · test: owed: guard-first'
has DIF-001 'knob: synonym matching · test-value: a fixed synonym table · prod-value: the synonym service · why-safe: the table covers'
has SEAM-001 'service: the mail provider · chosen: D-001 · credentials: not-yet · probe: owed · quirks: none yet'; has SEAM-002 'evidence: owed'
has HOS-005 'protects: INV-002 · disable: the guard that protects INV-002 · test: owed: spec-only — ticket · origin: plan INV-002'; has RULE-004 'tier: 1 · test: owed: spec-only — ticket · origin: plan REQ-005'; is ROW-017 12 tests/invariants/golden/synonyms.golden; is ROW-001 12 -
# left out: what DevAgent owns
for x in proved-red test_feed_repeat test_hostility_dupes extractors/invariant 'golden:' 'module:' 'match:' tests/contract SUP-001 EXC-002 'footer'"'"'s support link'; do
  cut -f1-11 "$T/rows" | grep -qF -- "$x" && fail "a left-out field is carried: $x"; done
has ROW-013 'derived-from: INV-001 · origin: domain property-form'; col ROW-013 11 | grep -q 'test:' && fail "ROW-013's test path is carried"
# each ROW row gives its obligation back whole
give() { awk -F'\t' -v INV=INVENTORY.md 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  BEGIN { while ((getline l < INV) > 0) if (l ~ /^ROW-[0-9]+ \|/) { split(l, a, "|"); ob[tr(a[1])] = tr(a[6]); o[++n] = tr(a[1]) } }
  $2 == "row" { P[$1] = $8; F[$1] = $9 } $2 == "tr" { s = $11; sub(/^separator: "/, "", s); sub(/"$/, "", s); k = $1; sub(/.*-T/, "", k); J[$3] = J[$3] s k ". " $8 }
  END { for (i = 1; i <= n; i++) { id = o[i]; g = (id in J) ? P[id] " transitions:" J[id] : (F[id] == "what the promise says is not what is observed" ? P[id] : P[id] " " F[id])
      if (g != ob[id]) { print id; bad = 1 } } exit bad }' "$T/rows"; }
give > "$T/out" || fail 'a ROW row is not given back whole'
# a `; ` separator, and a number inside a transition's words, are read too
fresh; sed 's/S01\/saved · a confirmation/S01\/saved · P12. a confirmation/; s/ ; 3\. /; 3. /' INVENTORY.md > I.x && mv I.x INVENTORY.md; rows
is ROW-004-T1 8 'anonymous at S01 · search and email fields · save · S01/saved · P12. a confirmation email is sent'
is ROW-004-T2 8 'anonymous at the confirmation email · Confirm link · click · S02/active · the saved search shows as active'; is ROW-004-T3 11 'separator: "; "'
give > "$T/out" || fail "the \`; \` separator is not given back whole"
# a census with pipes is carried as written; a last transition's trailing separator is kept
fresh; sed 's/sites: every digest template :: guarded/sites: every digest template|footer :: guarded/; s/the job opened is the one listed |/the job opened is the one listed; |/' INVENTORY.md > I.x && mv I.x INVENTORY.md; rows
has RULE-001 'census: sites: every digest template|footer :: guarded: those rendering the support footer'; give > "$T/out" || fail 'a trailing separator is not given back whole'
# the later-phase row and the record sit in no step; a later-phase row in a step is flagged
fresh; pt_set 'step S05' 'step S05 | name: synonyms | modules: search | builds-on: S02 | rows: ROW-017 ROW-020 | lane: devagent'; pt_check; pt_has 'class ROW-020 — a later-phase row, in step S05'
fresh; pt_set 'step S05' 'step S05 | name: synonyms | modules: search | builds-on: S02 | rows: ROW-017 DIF-003 | lane: devagent'; pt_check; pt_has 'class DIF-003 — a record, in step S05'
# an unread line, a ROW line out of form, and a missing golden set are flagged, never dropped
fresh; pt_after RULE-003 'widget | WID-001 | something the schema has no kind for'; pt_check; [ "$PT_RC" -eq 1 ] || fail 'an unread line passes'; pt_has 'unread "widget | WID-001'
fresh; pt_set ROW-019 'ROW-019 | behavior | REQ-012 | anonymous | a footer'; pt_check; pt_has 'unread ROW-019 — a ROW line with fewer than its eight fields'
fresh; pt_set ROW-019 'ROW-019 | widget | REQ-012 | anonymous | n/a | A footer. | REQ-012 | owed: spec-only — first stage'; pt_check; pt_has 'unread ROW-019 — the kind "widget"'
fresh; pt_set EXC-001 'exception | EXC-001 | the confirmation email | RULE-009 | a reply'; pt_check; pt_has 'unread EXC-001 — RULE-009 is no rule'
fresh; rm tests/invariants/golden/synonyms.golden; pt_check; pt_has "golden ROW-017 — its golden set is not in ViD's repository"
# --short, and no PLAN.md
fresh; rows --short; p=$(col ROW-004 8); [ "$p" = "The new subscriber: hears of the board on a forum (off-screen), saves a search, …" ] || fail "--short gives [$p]"
rm PLAN.md; rows; [ "$(grep -c -v '^#' "$T/rows")" -eq 41 ] || fail 'rows with no PLAN.md is not the 35 inventory rows and 6 transitions'
# --added prints the origin: plan lines as written
fresh; sh "$CHECKS/planner.sh" rows --added > "$T/added"; grep -E 'origin: plan' INVENTORY.md | cmp -s - "$T/added" && [ "$(grep -c . "$T/added")" -eq 3 ] || fail 'rows --added is not the 3 origin: plan lines as written'
exit 0
