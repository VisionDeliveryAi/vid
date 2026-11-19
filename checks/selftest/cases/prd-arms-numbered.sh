#!/bin/sh
# Purpose: selftest case — fail conditions in numbered parts (0.26.11.1.2, R13, FC-1). The 0.9.4 good fixture
# raised to `grammar: 0.26.11.1.2`, a plain: on every demand item and invariant and each fail-if written `(1) …; (2) …`
# (at its ", or "s) acquits — REQ-005's noun "or" inside its one part is no split. Convicts unless, under that grammar,
# join 3 refuses a fail-if that does not open `(1) `, numbers that skip or repeat, and an empty part (in the middle and
# at the end); a plain: holding a number found only as a part marker is refused by join 21; join 14 and --arms read
# the parts (an amendment's arms: counts the numbered parts, its was: is the part without its marker);
# checks/inventory.sh counts a Tier-0 item's arms by its numbered parts; and the consolidation's arm ledger flags a part
# lost between two versions. Under 0.9.8.1 the same unnumbered fail-if acquits and inventory.sh counts as before. The
# text parts (vid-create-prd's paragraph, the wording lens, the template's grammar) are skipped where skills/ is absent
# (a project). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
COURT="$CHECKS/prd.sh"
fail() { echo "prd-arms-numbered: $*" >&2; sh "$COURT" v.md 2>&1 | grep -E '^GAP' | head -5 >&2 || true; exit 1; }
conv() { # $1 the grammar, $2 1 to number the fail-ifs
  awk -v g="$1" -v num="$2" 'NR <= 3 && /^grammar: 0\.9\.4$/ { print "grammar: " g; next }
  /^(REQ|INV)-[0-9]+( AMENDED)? \|/ { if (num && match($0, /fail-if: [^|]*[^ |]/)) { f = substr($0, RSTART + 9, RLENGTH - 9); n = 1; o = "(1) "
      while ((i = index(f, ", or ")) > 0) { o = o substr(f, 1, i - 1) "; (" ++n ") "; f = substr(f, i + 5) }
      $0 = substr($0, 1, RSTART + 8) o f substr($0, RSTART + RLENGTH) }
    print $0 " | plain: The owner reads this rule in plain words"; next }
  { print }' "$CHECKS/selftest/fixtures/prd-094-good.md"; }
conv 0.26.11.1.2 1 > base.md
grep -qx 'grammar: 0.26.11.1.2' base.md && grep -q '^REQ-005 .*fail-if: (1) a feed outage or re-poll loses' base.md || fail 'the fixture did not convert'
cp base.md v.md; sh "$COURT" v.md > out 2>&1 || fail 'the numbered base does not acquit'
# REQ-001's fail-if replaced → v.md
fi1() { awk -v f="$1" 'index($0, "REQ-001 ") == 1 { sub(/fail-if: [^|]*\|/, "fail-if: " f " |") } { print }' "${2:-base.md}" > v.md
  grep -qF "fail-if: $1 |" v.md || fail "the mutation '$1' did not apply"; }
refused() { fi1 "$1"; if sh "$COURT" v.md > out 2>&1; then fail "acquitted: $2"; fi
  grep -qF "GAP  join 3 (REQ-001): $3" out || { cat out >&2; fail "no join 3 line for: $2"; }; }
refused 'a digest repeats a job already delivered for that search' 'an unnumbered fail-if' "the fail-if does not open '(1) '"
refused '(1) a digest repeats a job; (3) two digests arrive in one day' 'numbers that skip' 'the fail-if'"'"'s part numbers skip or repeat'
refused '(1) a digest repeats a job; (2) two digests arrive; (2) a third arrives' 'a repeated number' 'the fail-if'"'"'s part numbers skip or repeat'
# a marker of any length, or after another separator, left inside a part
refused '(1) a digest repeats a job; (100) two digests arrive in one day' 'a three-digit marker' 'the fail-if'"'"'s part numbers skip or repeat'
refused '(1) a digest repeats a job;(2) two digests arrive in one day' 'a marker after ";" with no space' 'the fail-if'"'"'s part numbers skip or repeat'
refused '(1) a digest repeats a job, (2) two digests arrive in one day' 'a marker after ", "' 'the fail-if'"'"'s part numbers skip or repeat'
refused '(1) ; (2) two digests arrive in one day' 'an empty first part' 'the fail-if has an empty part'
refused '(1) a digest repeats a job; (2)' 'an empty last part' 'the fail-if has an empty part'
fi1 '(1) a digest repeats a job; (2) two digests arrive in one day; (3) a digest names no search'
sh "$COURT" v.md > out 2>&1 || fail 'three well-numbered parts were refused'
# an older grammar: the same file unnumbered acquits, as today
conv 0.9.8.1 0 > v.md
sh "$COURT" v.md > out 2>&1 || fail 'an unnumbered fail-if under 0.9.8.1 was refused'
grep -q 'join 3' out && fail 'join 3 spoke under 0.9.8.1'
# a grammar of five parts just below the numbered one (0.26.11.1.1) is older: compared on every component
conv 0.26.11.1.1 0 > v.md
sh "$COURT" v.md > out 2>&1 || fail 'an unnumbered fail-if under 0.26.11.1.1 was refused'
# join 21: REQ-002's effective row says 2 only as a part marker
awk 'index($0, "REQ-002 AMENDED ") == 1 { sub(/plain: [^|]*$/, "plain: The owner reads rule 2 in plain words") } { print }' base.md > v.md
if sh "$COURT" v.md > out 2>&1; then fail 'a plain: number found only as a part marker was accepted'; fi
grep -qF "GAP  join 21 (REQ-002): plain: holds the number '2'" out || { cat out >&2; fail 'join 21 did not name the marker number'; }
# join 14 and --arms read the parts: REQ-002's base gains a noun "or" inside part 1 (old split: three arms, arms: two)
awk 'index($0, "REQ-002 | ") == 1 { sub(/after its address unsubscribed;/, "after its address unsubscribed or paused;") } { print }' base.md > v.md
grep -q 'unsubscribed or paused; (2)' v.md || fail 'the noun-or mutation did not apply'
sh "$COURT" v.md > out 2>&1 || { cat out >&2; fail 'join 14 counted the base parts other than by their numbers'; }
sh "$COURT" --arms v.md > arms.txt 2>&1 || fail '--arms exited non-zero'
grep -qF 'REQ-002 arm 1 strengthened | was: a digest arrives after its address unsubscribed or paused | now: (1) a digest arrives more than one day' arms.txt \
  || { cat arms.txt >&2; fail '--arms does not list part 1 without its marker'; }
# inventory.sh: a Tier-0 item of three numbered parts, no "or" in it, with one probe: 3 arms (0.9.8.1, an unnumbered text: as split today)
mkdir p; cd p
printf '```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
mkdir -p tests; for t in a h1; do printf 'ROW RULE REQ INV HOS\n' > "tests/test_$t.py"; done
printf '# PRD\ngrammar: 0.26.11.1.2\n\n```vid-prd\nREQ-012 | functional | T0 | consent mail | fail-if: (1) a mail is sent with consent off; (2) the send is recorded twice; (3) a paused address gets mail\n```\n' > PRD.md
printf '# Inventory\n\n```vid-inventory\nROW-001 | behavior | send | user | n/a | consent off: no mail is sent | REQ-012 | tests/test_a.py | proved-red: abc1234\nhostility | HOS-001 | send with consent off through the send form | protects: REQ-012 | disable: the consent check | tests/test_h1.py | proved-red: abc1234\n```\n' > INVENTORY.md
sh "$CHECKS/inventory.sh" > ../inv.out 2>&1 || :
grep -q '^NOTE  REQ-012 — 3 arms, 1 probe' ../inv.out || { cat ../inv.out >&2; fail 'inventory.sh did not count the three numbered parts'; }
printf '# PRD\ngrammar: 0.9.8.1\n\n```vid-prd\nREQ-012 | functional | T0 | consent mail | fail-if: a mail is sent with consent off or paused, or the send is recorded twice\n```\n' > PRD.md
sh "$CHECKS/inventory.sh" > ../inv.out 2>&1 || :
grep -q '^NOTE  REQ-012 — 3 arms, 1 probe' ../inv.out || { cat ../inv.out >&2; fail 'inventory.sh under 0.9.8.1 no longer counts by the old split'; }
cd "$T"
# the consolidation's arm ledger: a second amendment of REQ-002 drops part 2, withdrawn under a human answer
cp base.md PRD.md
cat >> PRD.md <<'APP'

### 2026-08-30 (owner answer — the second unsubscribe ruling)

```vid-prd
REQ-002 AMENDED | functional | T1 | Every digest carries a working one-click unsubscribe that stops all digests for that address within one hour. | fail-if: (1) a digest arrives more than one hour after its address unsubscribed | serves: consent exit — the trust floor of an email product | authority: authoritative | source: seed, A-010 | covers: DIM-consent | phase: pilot | feature: FEAT-03 | arms: 1 strengthened, 2 withdrawn A-010 | plain: The owner reads this rule in plain words
```

```vid-prd-answers
A-010 | human | 2026-08-30 | Q: may the unsubscribe link ask for a sign-in? | A: the sign-in rule is dropped; only the one-hour bound stays | settles: REQ-002
```
APP
cp PRD.md v.md; sh "$COURT" PRD.md > out 2>&1 || fail 'the seeded consolidation input is not court-green'
sh "$CHECKS/prd-consolidate.sh" PRD.md --date 2026-09-21 > cons.txt 2>&1 || { cat cons.txt >&2; fail 'the consolidation refused'; }
grep -qE '^## REQ-002 — 3 rows — arms first=2 consolidated=1 — arm-losing' .vid/consolidation-arms-2026-09-21.md \
  || { cat .vid/consolidation-arms-2026-09-21.md >&2; fail 'the ledger does not flag the part lost'; }
# the text: the template's grammar, vid-create-prd's paragraph, the wording lens (plugin repository only)
K="$CHECKS/../skills"; [ -d "$K/vid-create-prd" ] && [ -f "$CHECKS/../templates/PRD.md" ] || { echo 'needs skills/ and templates/'; exit 77; }
sed -n 2p "$CHECKS/../templates/PRD.md" | grep -qx 'grammar: 0.26.11.1.2' || fail "the PRD template's grammar is not 0.26.11.1.2"
grep -qF 'fail-if: (1) {{FAILING_CASE}} |' "$CHECKS/../templates/PRD.md" || fail "the PRD template's row is not numbered"
tr '\n' ' ' < "$K/vid-create-prd/SKILL.md" | tr -s ' ' | grep -qF '**A fail-if in numbered parts** (0.26.11.1.2, R13). Under `grammar: 0.26.11.1.2` the fail-if is written `fail-if: (1) <what a wrong product does>; (2) <another> …`' \
  || fail 'vid-create-prd lacks the numbered-parts paragraph'
tr '\n' ' ' < "$K/vid-create-prd/passes/wording-lens.md" | tr -s ' ' | grep -qF 'under `grammar: 0.26.11.1.2` an arm is one numbered part' || fail 'the wording lens does not count numbered parts'
exit 0
