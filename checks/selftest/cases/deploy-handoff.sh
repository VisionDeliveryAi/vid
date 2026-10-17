#!/bin/sh
# Purpose: selftest case — the deploy handoff (v0.9.3 spec 3.14, R19; Phase
# E's cut line). In the plugin repository: vid-deploy opens with the claim
# computed by `sh checks/metrics.sh completion`; the skill and the
# DEPLOYMENT template name the same three rollback choices (application
# rollback keeping a compatible database, forward repair, restoration from
# the snapshot with the recovery point and the writes at risk) and neither
# restores unconditionally. Everywhere: on a toy repository under
# `grammar: 0.9.3` with an unmet row the command the skill names prints
# "not complete" with the closure. Env: CHECKS.
set -eu
fail() { echo "deploy-handoff: $*" >&2; exit 1; }
FL=$(mktemp -d)
SK="$CHECKS/../skills/vid-deploy/SKILL.md"; TP="$CHECKS/../templates/DEPLOYMENT.md"
if [ -f "$SK" ] && [ -f "$TP" ]; then
  sed -n '/^## The claim first/,/^## /p' "$SK" | grep -q 'sh checks/metrics.sh completion' || fail 'vid-deploy does not open with the computed claim'
  [ "$(grep -n '^## ' "$SK" | head -n 1 | cut -d: -f2-)" = '## The claim first — "development complete" is computed (v0.9.3 3.14, R19)' ] || fail 'the claim is not the first section'
  for f in "$SK" "$TP"; do
    tr '\n' ' ' < "$f" | tr -s ' ' > "$FL/flat"
    for c in 'application rollback keeping a compatible database' 'forward repair' 'restoration from the snapshot' 'recovery point' 'writes at risk'; do
      grep -qi -- "$c" "$FL/flat" || { rm -f "$FL/flat"; fail "$f does not name: $c"; }
    done
    grep -qiE 'roll back = redeploy the previous build ref \+ restore|rollback is recorded, not designed' "$FL/flat" && { rm -f "$FL/flat"; fail "$f still restores unconditionally"; }
    rm -f "$FL/flat"
  done
fi
T=$(mktemp -d); trap 'rm -rf "$T" "$FL"' EXIT
cd "$T"; git init -q; mkdir -p checks/extractors tests/invariants app .vid/ledger-results
cp "$CHECKS/metrics.sh" "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '#!/bin/sh\n# Purpose: r\n[ -f "${1:-}" ] || exit 0\ngrep "^case " "$1"\n' > checks/extractors/results.sh
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# T\n\n## Items\n\n```vid-prd\nREQ-001 | functional | T1 | One. | fail-if: x | serves: x | phase: pilot\n```\n' > PRD.md
printf '# Purpose: toy — REQ-001\n' > app/m.sh; printf '# Purpose: ledger\n' > tests/invariants/t.sh
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | tests/invariants/t.sh\n```\n' > INVENTORY.md
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm r; S=$(git rev-parse --short=12 HEAD)
printf 'case tests/invariants/t.sh::t[ROW-001] failed 0.1\n' > ".vid/ledger-results/$S.full.xml"
OUT=$(sh checks/metrics.sh completion)
printf '%s\n' "$OUT" | grep -qx 'closure unfinished-implementation n=1 ROW-001' || fail 'the closure line'
printf '%s\n' "$OUT" | grep -q '^not complete — unmet 1' || fail 'the claim is not "not complete"'
exit 0
