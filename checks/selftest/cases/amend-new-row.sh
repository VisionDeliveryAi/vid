#!/bin/sh
# Purpose: selftest case — a row new at the commit that changes its parent's fail-if gets no event (v0.26.10.3 R1; §5
# amend-new-row). A toy repository with the real post-commit hook under `grammar: 0.9.3`: REQ-001 with ROW-001. One
# commit changes REQ-001's fail-if and adds ROW-002 under it. Convicts unless ROW-001 gets `law-changed` and ROW-002
# neither `law-changed` nor `amended`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q; mkdir -p checks/hooks .vid
cp "$CHECKS/inventory.sh" "$CHECKS/prd.sh" checks/; cp "$CHECKS/hooks/post-commit" checks/hooks/; chmod +x checks/hooks/post-commit
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "amend-new-row: $*" >&2; exit 1; }
prd() { printf '# Toy — PRD\n\ngrammar: 0.9.3\n\n```vid-prd\nREQ-001 | functional | T1 | A link lasts a while. | fail-if: %s | serves: x | authority: authoritative | source: A-001 | phase: pilot | plain: links expire\n```\n' "$1"; }
O='owed: prerequisite — a clock; paid at slice 2'
printf '.vid/\n' > .gitignore; prd 'a link works after seven days' > PRD.md
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | a link refuses once expired | REQ-001 | %s\n```\n' "$O" > INVENTORY.md
g add -A; g commit -qm root; git config core.hooksPath checks/hooks
EV=.vid/metrics-events; : > "$EV"
prd 'a link works after three days' > PRD.md
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | a link refuses once expired | REQ-001 | %s\nROW-002 | behavior | s2 | anon | - | a link refuses after three days | REQ-001 | %s\n```\n' "$O" "$O" > INVENTORY.md
g add -A; g commit -qm 'the change and its new row' > /dev/null 2>&1 || fail 'the commit was refused'
grep -q "^law-changed row=ROW-001 sha=$(git rev-parse --short=12 HEAD) item=REQ-001 " "$EV" || fail "ROW-001 is not to confirm: $(cat "$EV")"
grep -q 'row=ROW-002 ' "$EV" && fail "the new row got an event: $(cat "$EV")"
exit 0
