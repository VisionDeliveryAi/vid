#!/bin/sh
# Purpose: selftest case — an amended obligation wipes its row's verdicts
# (v0.9.3 spec 3.7, R10; §7 case 7, second half). Real commits in a
# temporary repository with the real hooks installed (pre-commit,
# commit-msg, post-commit) under `grammar: 0.9.3`, the PRD the known-good
# fixture. Convicts unless: a commit changing one obligation records one
# `amended row=ID sha=<that commit>`; a commit refused by commit-msg records
# no amendment (v0.9.6.2 3.4: only its own `refused` event); a PRD commit changing one item's `fail-if:` records one event
# per row derived from it and `failif-amendment n=1` (the fixed grep — the
# 0.9.2 grep counted zero on the lowercase field); an AMENDED row changing
# only `phase:` records none; a consolidation commit records neither; and
# under a 0.9.2 block the post-commit hook records nothing. v0.9.8 (R6): each event names its cause, by=obligation
# or by=fail-if. Env: CHECKS.
set -eu
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'   # v0.9.5 3.11: every event line ends ` at=<UTC>`
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh prd-consolidate.sh lawfiles; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
O='owed: prerequisite — a mail capture the harness lacks; paid at slice 2'
inv() { printf '# toy\n```vid-inventory\n%s\nROW-001 | behavior | REQ-001 | n/a | n/a | %s | REQ-001 | %s\nROW-002 | behavior | REQ-001 | n/a | n/a | only new matches reach a digest | REQ-001 | %s\nROW-003 | behavior | REQ-002 | n/a | n/a | %s | REQ-002 | %s\nROW-004 | behavior | REQ-003 | n/a | n/a | a synonym query finds its match | REQ-003 | %s\n```\n' "$1" "$2" "$O" "$O" "$3" "$O" "$O" > INVENTORY.md; }
inv 'grammar: 0.9.3' 'one digest per saved search per day' 'the unsubscribe link stops every digest'
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
EVF=.vid/metrics-events; : > "$EVF"
fail() { echo "amended: $*" >&2; cat "$EVF" >&2; exit 1; }
# 1. one obligation changed → one event naming that commit
inv 'grammar: 0.9.3' 'one digest per saved search per day' 'the unsubscribe link stops every digest within one day'
g add INVENTORY.md && g commit -qm 'ROW-003 obligation

Decisions: none — the owner narrowed the unsubscribe bound' >/dev/null 2>&1 || fail 'the obligation commit was refused'
[ "$(grep -c . "$EVF")" -eq 1 ] && grep -qxE "amended row=ROW-003 sha=$(git rev-parse --short=12 HEAD) by=obligation $ATRE" "$EVF" || fail 'one obligation change is not exactly one amended event naming its commit'
# 2. a commit refused by commit-msg records nothing
: > "$EVF"; B=$(git rev-parse HEAD)
inv 'grammar: 0.9.3' 'two digests never arrive in one day' 'the unsubscribe link stops every digest within one day'
g add INVENTORY.md
if g commit -qm 'no decisions line' >/dev/null 2>&1; then fail 'commit-msg accepted a message with no Decisions line'; fi
[ "$(git rev-parse HEAD)" = "$B" ] || fail 'the refused commit landed'
grep -q '^amended ' "$EVF" && fail 'a refused commit recorded an amendment'
[ "$(grep -c . "$EVF")" -eq 1 ] && grep -q '^refused phase=commit-msg by=decisions ' "$EVF" || fail 'the refusal is not the one line recorded'
g reset -q --hard "$B"
# 3. one fail-if changed in place → one event per derived row, failif-amendment n=1
sed 's/^\(REQ-001 | .*| fail-if: \)a digest repeats a job already delivered for that search/\1a digest repeats any job already delivered to that address/' PRD.md > p && mv p PRD.md
git diff --quiet PRD.md && fail 'the fixture edit did not change REQ-001'
sh checks/prd.sh >/dev/null 2>&1 || fail 'the edited PRD fails its own court'
g add PRD.md && g commit -qm 'REQ-001 fail-if

Decisions: none — the owner widened the repeat to any search' >/dev/null 2>&1 || fail 'the fail-if commit was refused'
H=$(git rev-parse --short=12 HEAD)
grep -qxE "failif-amendment n=1 $ATRE" "$EVF" || fail 'the fixed grep did not count the lowercase fail-if'
grep -qxE "amended row=ROW-001 sha=$H by=fail-if $ATRE" "$EVF" && grep -qxE "amended row=ROW-002 sha=$H by=fail-if $ATRE" "$EVF" || fail 'not one event per row derived from the amended item'
[ "$(grep -c '^amended ' "$EVF")" -eq 2 ] || fail 'a row not derived from the item was amended'
# 4. an AMENDED row changing only phase: → no amended event
: > "$EVF"
L=$(grep '^REQ-003 | ' PRD.md)
printf '\n### Append 2026-09-23 (/vid fix correction)\n\n```vid-prd\n%s | phase: pilot\n```\n' "$(printf '%s\n' "$L" | sed 's/^REQ-003 |/REQ-003 AMENDED |/')" >> PRD.md
g add PRD.md && g commit -qm 'REQ-003 phase only

Decisions: none — membership stated, nothing changed' >/dev/null 2>&1 || fail 'the phase-only amendment was refused'
grep -q '^amended ' "$EVF" && fail 'a phase-only AMENDED row recorded an amendment'
# 5. a consolidation commit records neither
: > "$EVF"
sh checks/prd-consolidate.sh PRD.md --date 2026-09-23 >/dev/null 2>&1 || fail 'the consolidation script refused the fixture'
g add -A && g commit -qm 'consolidation

Decisions: none — the mechanical copy (7a)' >/dev/null 2>&1 || fail 'the consolidation commit was refused'
git show --name-only --format= HEAD | grep -q '^PRD-HISTORY-2026-09-23.md$' || fail 'the consolidation did not add its history file'
[ ! -s "$EVF" ] || fail 'a consolidation recorded an amendment or a failif count'
# 6. a 0.9.2 block records nothing
sed 's/^grammar: 0.9.3$/grammar: 0.9.2/' INVENTORY.md > i && mv i INVENTORY.md
g add INVENTORY.md && g commit -qm 'to 0.9.2

Decisions: none' >/dev/null 2>&1 || fail 'the grammar commit was refused'
: > "$EVF"
inv 'grammar: 0.9.2' 'one digest per saved search per day' 'nothing arrives after the unsubscribe'
g add INVENTORY.md && g commit -qm 'obligation under 0.9.2

Decisions: none' >/dev/null 2>&1 || fail 'the 0.9.2 obligation commit was refused'
[ ! -s "$EVF" ] || fail 'the post-commit hook recorded under a 0.9.2 block'
exit 0
