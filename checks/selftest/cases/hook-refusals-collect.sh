#!/bin/sh
# Purpose: selftest case — every refusal of the pre-commit hook goes on to the next check (FB-4 C2): the ones no other
# case stages beside a second fault. Stub courts, one fault each, and in the same commit a later one (the seam court, or the
# grammar line lowered), or an earlier one where nothing comes after: decisions-enforced, decisions-promissory (a
# "planned" reference), decisions-label (a replaced-by: mark), hosting-access, no-plan-step, red-stamp, final-review. Each
# attempt names both in by= and in one `refused by:` line, and says both reasons. index-copy ends the hook early, and
# still names what was found before it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/p"; cd "$T/p"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-refusals-collect: $*" >&2; cat .vid/out >&2 2>/dev/null; exit 1; }
# a stub plan.sh: its guard and its red-stamp check refuse when told to
printf '#!/bin/sh\n# Purpose: stub plan.sh\ncase "$1" in\n  guard) cat > /dev/null; [ ! -f .fail/guard ] || { echo "guard refuses"; exit 1; } ;;\n  redstamp) [ ! -f .fail/redstamp ] || { echo "redstamp refuses"; exit 1; } ;;\n  home-of) exit 1 ;;\nesac\nexit 0\n' > checks/plan.sh
mkdir -p .vid; printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md; printf '# P\ngrammar: 0.9.5\n' > PRD.md; printf '# Inventory\n' > INVENTORY.md; printf '# Architecture\n' > ARCHITECTURE.md
g add -A; g commit -qm base
# both <by list> <reason> <reason>: the commit staged here is refused once, for both
both() { : > .vid/hook-times; if VID_ROLE=${ROLE:-} sh checks/hooks/pre-commit > .vid/out 2>&1; then fail "passed: $1"; fi
  b=$(sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times); [ "$b" = "$1" ] || fail "by=$b, not $1"
  [ "$(grep -c 'refused by:' .vid/out)" = 1 ] && grep -q "refused by: $(printf '%s' "$1" | tr ',' ' ')\$" .vid/out || fail "$1: not one line naming both"
  for m in "$2" "$3"; do grep -qF -- "$m" .vid/out || fail "$1: not said: $m"; done
  rm -f .fail/*; g reset -q --hard; }
dec() { printf -- '- **D-001** a thing%s\n' "$1" >> DECISIONS.md; g add DECISIONS.md; : > .fail/seams; }
dec ' | why: a reason | scope: project'
both decisions-enforced,seams 'entries without an enforcement ref' 'seams refuses'
dec ' | why: a reason | enforced: planned | scope: project'
both decisions-promissory,seams 'promissory enforced: ref' 'seams refuses'
dec ' | replaced-by: D-099 | why: a reason | enforced: convention | scope: project'
both decisions-label,seams 'replaced-by: marks out of form' 'seams refuses'
printf '\n```vid-hosting\nplatform: somewhere\naccess: a value\n```\n' >> ARCHITECTURE.md; g add ARCHITECTURE.md; : > .fail/seams
both hosting-access,seams 'records access only by its shape' 'seams refuses'
stage one; : > .fail/guard; : > .fail/seams
both no-plan-step,seams 'guard refuses' 'seams refuses'
printf 'more\n' >> INVENTORY.md; printf '# P\ngrammar: 0.9.4\n' > PRD.md; g add -A; : > .fail/redstamp
both red-stamp,prd-grammar 'redstamp refuses' 'a grammar is never lowered'
# the index copy fails: git's checkout-index alone, through a wrapper
mkdir "$T/bin"; printf '#!/bin/sh\n[ "${1:-}" != checkout-index ] || exit 1\nexec "%s" "$@"\n' "$(command -v git)" > "$T/bin/git"; chmod +x "$T/bin/git"
printf '#!/bin/sh\necho a\n' > app/a.sh; g add app; printf 'x\n' > app/untracked.txt
P=$PATH; PATH="$T/bin:$PATH"; both purpose-header,index-copy "'app/a.sh'" 'the index could not be copied'; PATH=$P; rm -f app/untracked.txt
# final-review is the last check: a court before it, at a first commit of the spec (HEAD carries no checks/)
rm -rf .git; git init -q; g add .gitignore; g commit -qm first
printf '# P\ngrammar: 0.9.5\n\n```vid-prd-answers\n```\n' > PRD.md; g add -A; : > .fail/seams
ROLE=fix; b0=$(git diff --cached --name-only | grep -c '^INVENTORY.md$'); [ "$b0" = 1 ] || fail 'the fixture does not add INVENTORY.md'
both seams,final-review 'seams refuses' 'no new `review: final` line'
exit 0
