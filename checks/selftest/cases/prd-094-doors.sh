#!/bin/sh
# Purpose: selftest case — the append doors under grammar 0.9.4 (v0.9.4
# spec §3.8, §7 case 13). Real commits in a temporary repository with the
# real hooks installed, the PRD the 0.9.4 known-good fixture: a
# vid-add-shaped append without feature: is refused at the commit, with it
# accepted; a vid-add T0 item resting on a skipped answer (a ViD decision)
# with `owner-decision/no` is refused, with its carrier and `/yes`
# accepted; a vid-fix-shaped AMENDED row citing `fix <date>` with a new
# value is accepted and counted in values-unchecked=. The same file
# consolidated twice acquits both times and the second run is
# byte-identical — the exemption goes by entry kind and survives the move
# into the base. Under --pause, the row citing `fix <date>` convicts: a
# create-prd pause cites no door sitting. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "prd-094-doors: $*" >&2; exit 1; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh prd-consolidate.sh lawfiles; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
cp "$CHECKS/selftest/fixtures/prd-094-good.md" PRD.md
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
# door <heading> <body> <message>: append a dated section and commit it through the hooks; prints ACCEPTED or REFUSED
door() {
  cp PRD.md PRD.base
  printf '\n### 2026-09-26 (%s)\n\n%s\n' "$1" "$2" >> PRD.md
  g add PRD.md
  if g commit -qm "$3

Decisions: none — a door probe" >out.txt 2>&1; then echo ACCEPTED; else cp PRD.base PRD.md; g reset -q; echo REFUSED; fi
}
ADD='```vid-prd
REQ-070 | functional | T2 | A subscriber can pause all digests for a holiday. | fail-if: a digest arrives while the subscriber paused them | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis | phase: pilot
```'
[ "$(door '/vid add' "$ADD" 'add without feature')" = REFUSED ] || fail 'an append without feature: was accepted'
grep -qF 'GAP  join 16 (REQ-070): no feature:' out.txt || fail 'the refusal does not name join 16'
[ "$(door '/vid add' "$(printf '%s\n' "$ADD" | sed 's/| phase: pilot$/| phase: pilot | feature: FEAT-03/')" 'add with feature')" = ACCEPTED ] || { cat out.txt >&2; fail 'the lawful append was refused'; }
T0='```vid-prd-answers
A-010 | model_proposed | 2026-09-26 | Q: may support staff see a subscriber'"'"'s saved searches? | A: never — support sees the address and the send log only | settles: INV-011
```

```vid-prd
INV-011 | invariant | T0 | Support staff never see a subscriber'"'"'s saved searches. | serves: saved searches reveal job hunting | authority: provisional | confirms_via: owner-decision/no | source: A-010 | phase: pilot | feature: FEAT-03
```'
[ "$(door '/vid add' "$T0" 'add a T0 item on a skipped answer')" = REFUSED ] || fail 'a T0 item on a skipped answer with /no was accepted'
grep -qF 'GAP  join 18 (INV-011)' out.txt || fail 'the refusal does not name join 18'
T0Y=$(printf '%s\n' "$T0" | sed 's|confirms_via: owner-decision/no|confirms_via: owner-decision OQ-4/yes|')
T0Y="$T0Y

VID-QUESTION: (OQ-4) A-010 — May support staff ever see a subscriber's saved searches?"
[ "$(door '/vid add' "$T0Y" 'add a T0 item with its question')" = ACCEPTED ] || { cat out.txt >&2; fail 'the T0 item with its carrier and /yes was refused'; }
FIX='```vid-prd
REQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address that reaches a person within 48 hours. | fail-if: the footer lacks a support address, or mail to it bounces, or a reply takes longer than 48 hours | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: fix 2026-09-26 | covers: DIM-nfr-operability/support | phase: pilot | feature: FEAT-03 | arms: 1 retained, 2 retained
```'
[ "$(door '/vid fix correction' "$FIX" 'fix: a support bound')" = ACCEPTED ] || { cat out.txt >&2; fail 'the fix-shaped amendment with a new value was refused'; }
sh checks/prd.sh PRD.md --report 2>&1 | grep -q ' values-unchecked=1$' || fail "the fix row is not counted: $(sh checks/prd.sh PRD.md --report 2>&1 | tail -1)"
# consolidated twice: acquits both times, byte-identical; the door row keeps its exemption in the base
sh checks/prd-consolidate.sh PRD.md --date 2026-09-26 >c1.txt 2>&1 || { cat c1.txt >&2; fail 'the first consolidation refused'; }
grep -q '^REQ-012 | functional | T2 | .*within 48 hours.*| source: fix 2026-09-26 |' PRD.md || fail 'the fix row did not move into the base'
sh checks/prd.sh PRD.md >/dev/null 2>&1 || fail 'the consolidated file convicts'
sh checks/prd.sh PRD.md --report 2>&1 | grep -q ' values-unchecked=1$' || fail 'the exemption did not survive consolidation'
cp PRD.md PRD.first
sh checks/prd-consolidate.sh PRD.md --date 2026-09-27 >c2.txt 2>&1 || { cat c2.txt >&2; fail 'the second consolidation refused'; }
cmp -s PRD.md PRD.first || fail 'the second consolidation is not byte-identical'
sh checks/prd.sh PRD.md >/dev/null 2>&1 || fail 'the twice-consolidated file convicts'
# under --pause a door sitting reference convicts
if sh checks/prd.sh PRD.md --pause >/dev/null 2>&1; then fail 'a door reference acquits under --pause'; fi
sh checks/prd.sh PRD.md --pause --report 2>&1 | grep -qF "GAP  join 19 (REQ-012): cites the door sitting 'fix 2026-09-26' at a pause" || fail 'the --pause conviction does not name the door row'
exit 0
